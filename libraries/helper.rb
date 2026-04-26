require 'vault'
require 'timeout'

module Openbao
  class Client
    def initialize(node)
      @node = node
      setup!
    end

    def system_ca_file(node)
      if ::File.exist?('/etc/openbao/ca.pem')
        return '/etc/openbao/ca.pem'
      end

      case node['platform']
      when 'ubuntu', 'debian', 'kali'
        '/etc/ssl/certs/ca-certificates.crt'
      when 'centos', 'fedora', 'oracle'
        '/etc/pki/tls/certs/ca-bundle.crt'
      else
        '/etc/ssl/certs/ca-certificates.crt'
      end
    end

    def tls_enabled?
      ::File.exist?('/etc/openbao/cert.pem') &&
        ::File.exist?('/etc/openbao/key.pem')
    end

    def api_address
      if ENV['VAULT_ADDR']
        return ENV['VAULT_ADDR']
      elsif @node['roles'].include? 'vault'
        schema = tls_enabled? ? 'https' : 'http'
        if @node['openbao']['nodes'].include? @node['fqdn']
          host = @node['fqdn']
        else
          @node['openbao']['vip_hostname']
        end
        port = @node['openbao']['port'] || 8200

        "#{schema}://#{host}:#{port}"
      else
        @node['openbao']['url']
      end
    end

    def chef_vault_auth(key_path)
      vault_addr = api_address()
      mount = 'auth/chef'
      client_name = @node['fqdn']

      key = OpenSSL::PKey::RSA.new(::File.read(key_path))

      # --- 1. challenge ---
      uri = URI("#{vault_addr}/v1/#{mount}/challenge")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      if http.use_ssl?
        http.ca_file = system_ca_file(@node)
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = { client_name: client_name }.to_json

      res = http.request(req)
      raise "challenge failed: #{res.body}" unless res.code.to_i == 200

      data = JSON.parse(res.body)['data']

      challenge_id = data['challenge_id']
      nonce        = data['nonce']
      timestamp    = data['timestamp'].to_s
      method       = data['method']
      path         = data['path']

      # имитация python sleep((time.time() - x) * 5)
      # (можно убрать если сервер не требует)
      sleep 0.1

      # --- 2. string_to_sign ---
      string_to_sign = [
        client_name,
        challenge_id,
        nonce,
        timestamp,
        method,
        path
      ].join("\n")

      # --- 3. sign ---
      signature = key.sign(OpenSSL::Digest::SHA256.new, string_to_sign)
      signature_b64 = Base64.strict_encode64(signature)

      # --- 4. login ---
      uri = URI("#{vault_addr}/v1/#{mount}/login")

      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = {
        client_name: client_name,
        challenge_id: challenge_id,
        signature: signature_b64
      }.to_json

      res = http.request(req)
      raise "login failed: #{res.body}" unless res.code.to_i == 200

      body = JSON.parse(res.body)

      body.dig('auth', 'client_token')
    end

    def setup!
      Vault.address = api_address()
      if ENV['VAULT_TOKEN']
        Vault.token = ENV['VAULT_TOKEN']
      elsif ::File.exists? '/etc/openbao/root_token'
        token = read_local_token('/etc/openbao/root_token')
        if token
          Vault.token = token
        end
      elsif ::File.exists? '/etc/cinc/client.pem'
        token = chef_vault_auth('/etc/cinc/client.pem')
        if token
          Vault.token = token
        end
      end
      if !Vault.token
        raise 'cannot configure vault'
      end

      Vault.configure do |config|
        config.ssl_ca_cert = system_ca_file(@node)
      end
    end

    def init(secret_shares:, secret_threshold:)
      Vault.sys.init(
        secret_shares: secret_shares,
        secret_threshold: secret_threshold
      )
    end

    def write_local_secrets(unseal_keys, root_token, key_path, token_path)
      ::File.write(key_path, unseal_keys.join("\n"))
      ::File.chmod(0600, key_path)

      ::File.write(token_path, root_token)
      ::File.chmod(0600, token_path)
    end

    def read_local_unseal_keys(path)
      return [] unless ::File.exist?(path)

      ::File.readlines(path).map(&:strip).reject(&:empty?)
    end

    def read_local_token(path)
      return nil unless ::File.exist?(path)

      ::File.read(path).strip
    end

    def initialized_via_secret?(mount, path)
      !!read(path, mount)
    end

    def store_bootstrap_secret(mount, path, data)
      enable_kv2(mount)
      write(path, data, mount)
    end

    def normalize(path)
      path.sub(%r{/$}, '')
    end

    def status
      Vault.sys.seal_status
    end

    def sealed?
      status.instance_variable_get(:@sealed)
    end

    def initialized?
      Vault.sys.init_status.instance_variable_get(:@initialized)
    end

    def unseal(keys)
      raise 'Unseal keys must be an array' unless keys.is_a?(Array)

      keys.each do |key|
        Vault.sys.unseal(key)
        break unless sealed?
      end

      raise 'Still sealed' if sealed?

      true
    end

    def read(path, mount)
      secret = Vault.kv(mount).read(path)
      return nil unless secret

      secret.data
    rescue Vault::HTTPClientError => e
      return nil if e.message.include?('404')

      Chef::Log.error("Failed to read secret #{mount}/#{path}: #{e}")
      raise
    end

    def write(path, data, mount)
      Vault.kv(mount).write(path, data)

      Chef::Log.info("Secret written to #{mount}/#{path}")
      true
    rescue => e
      Chef::Log.error("Failed to write secret #{mount}/#{path}: #{e}")
      raise
    end

    def mount_exists?(path)
      mounts = Vault.sys.mounts.transform_keys(&:to_s)
      mounts.key?(path)
    end

    def enable_kv2(path)
      path = path.sub(%r{/$}, '')

      return true if mount_exists?(path)

      Vault.sys.mount(
        path,
        'kv',
        'generated by chef',
        {
          options: { version: 2 }
        }
      )

      Chef::Log.info("KV v2 mount enabled at #{path}")
      true
    rescue => e
      Chef::Log.error("Failed to enable KV v2 at #{path}: #{e}")
      raise
    end

    def enable_pki(path, max_lease_ttl: '3999d')
      path = path.sub(%r{/$}, '')

      return true if mount_exists?(path)

      Vault.sys.mount(
        path,
        'pki',
        'generated by chef',
        {
          config: {
            max_lease_ttl: max_lease_ttl
          }
        }
      )

      Chef::Log.info("PKI mount enabled at #{path}")
      true
    rescue => e
      Chef::Log.error("Failed to enable PKI at #{path}: #{e}")
      raise
    end

    def tune_mount(path, options = {})
      path = normalize(path)

      Vault.sys.mount_tune(path, options)

      Chef::Log.info("Tuned mount #{path} with #{options}")
      true
    rescue => e
      Chef::Log.error("Failed to tune mount #{path}: #{e}")
      raise
    end

    def get_mount_tune(path)
      path = normalize(path)

      Vault.sys.get_mount_tune(path)
    rescue => e
      Chef::Log.error("Failed to get mount tune for #{path}: #{e}")
      raise
    end

    def ls
      Vault.sys.mounts(path).keys
    rescue => e
      Chef::Log.error("Failed to get mount tune for #{path}: #{e}")
      raise
    end

    def unmount(path)
      path = normalize(path)

      unless mount_exists?(path)
        Chef::Log.info("Mount #{path} already absent, skipping unmount")
        return true
      end

      Vault.sys.unmount(path)

      Chef::Log.info("Unmounted Vault mount at #{path}")
      true
    rescue => e
      Chef::Log.error("Failed to unmount #{path}: #{e}")
      raise
    end

    def wait_for_health_ready(timeout: 120, interval: 2)
      Timeout.timeout(timeout) do
        loop do
          begin
            health = Vault.sys.health_status

            initialized = health.instance_variable_get(:@initialized)
            sealed = health.instance_variable_get(:@sealed)

            Chef::Log.info("Vault health: initialized=#{initialized}, sealed=#{sealed}")

            return true
          rescue Vault::HTTPClientError => e
            Chef::Log.warn("Vault not ready yet: #{e.message}")
          rescue => e
            Chef::Log.warn("Unexpected error: #{e}")
          end

          sleep interval
        end
      end
    end

    def wait_for_raft_ready(timeout: 120, interval: 2)
      Timeout.timeout(timeout) do
        loop do
          begin
            leader = Vault.sys.leader

            leader_address = leader['leader_address']
            self_is_leader = leader['is_self']

            if leader_address && !leader_address.empty?
              Chef::Log.info("Raft leader elected: #{leader_address}")
              Chef::Log.info("This node is leader: #{self_is_leader}")
              return true
            end

            Chef::Log.info('Waiting for Raft leader election...')
          rescue => e
            Chef::Log.warn("Raft not ready yet: #{e}")
          end

          sleep interval
        end
      end
    end

    def pki_root_exists?(mount)
      mount = normalize(mount)

      Vault.logical.read("#{mount}/cert/ca")
      true
    rescue Vault::HTTPClientError => e
      return false if e.message.include?('no default issuer currently configured')

      raise
    end

    def generate_root(mount, type: 'internal', common_name:, use_issuers: false, **opts)
      mount = normalize(mount)

      if pki_root_exists?(mount)
        Chef::Log.info("PKI root already exists at #{mount}, skipping generation")
        return false
      end

      path =
        if use_issuers
          "#{mount}/issuers/generate/root/#{type}"
        else
          "#{mount}/root/generate/#{type}"
        end

      payload = { common_name: common_name }.merge(opts)

      Vault.logical.write(path, payload)

      Chef::Log.info("Generated PKI root at #{mount} (#{type})")
      true
    end

    def pki_role(mount, name)
      mount = normalize(mount)

      res = Vault.logical.read("#{mount}/roles/#{name}")
      return nil unless res

      res.data
    rescue Vault::HTTPClientError => e
      return nil if e.message.include?('404')

      raise
    end

    def write_pki_role(mount, name, **opts)
      mount = normalize(mount)
      puts opts['allowed_domains']
      Vault.logical.write("#{mount}/roles/#{name}", opts)

      Chef::Log.info("Wrote PKI role #{name} at #{mount}")
      true
    rescue => e
      Chef::Log.error("Failed to write PKI role #{name}: #{e}")
      raise
    end

    def duration_to_seconds(str)
      match = str.match(/^(\d+)([smhd])$/)
      raise "Invalid duration: #{str}" unless match

      value = match[1].to_i
      unit  = match[2]

      case unit
      when 's' then value
      when 'm' then value * 60
      when 'h' then value * 3600
      when 'd' then value * 86_400
      else
        raise "Unsupported unit: #{unit}"
      end
    end

    def normalize_role(data)
      return {} unless data

      {
        allowed_domains: Array(data[:allowed_domains]).map(&:to_s).sort,
        allow_subdomains: data[:allow_subdomains],
        allow_any_name: data[:allow_any_name],
        allow_bare_domains: data[:allow_bare_domains],
        enforce_hostnames: data[:enforce_hostnames],
        allow_glob_domains: data[:allow_glob_domains],
        organization: data[:organization].is_a?(Array) ? data[:organization] : [data[:organization]],
        max_ttl: data[:max_ttl].to_s,
        ttl: data[:ttl].to_s
      }
    end

    def auth_methods
      Vault.sys.auths
    end

    def auth_exists?(path)
      auth_methods.transform_keys(&:to_s).key? (path)
    end

    def enable_auth(path, type, description = 'managed by chef')
      path = normalize(path)

      Vault.sys.enable_auth(path, type, description)

      Chef::Log.info("Enabled auth #{type} at #{path}")
      true
    end

    def disable_auth(path)
      path = normalize(path)

      Vault.sys.disable_auth(path)

      Chef::Log.info("Disabled auth at #{path}")
      true
    end

    def read_auth_config(path)
      Vault.logical.read("auth/#{normalize(path)}/config")&.data
    rescue Vault::HTTPClientError => e
      return nil if e.message.include?('404')

      raise
    end

    def read_policy(name)
      Vault.sys.policy(name)
    rescue Vault::HTTPError => e
      return nil if e.code == 404

      raise
    end

    def write_policy(name, rules_string)
      # Метод SDK обернет эту строку в { "rules": rules_string }
      Vault.sys.put_policy(name, rules_string)
    end

    def delete_policy(name)
      Vault.sys.delete_policy(name)

      Chef::Log.info("Policy written: #{name}")
      true
    rescue => e
      Chef::Log.error("Failed to write policy #{name}: #{e}")
      raise
    end

    def write_auth_config(path, data)
      Vault.logical.write("auth/#{normalize(path)}/config", data)
    end

    def pki_cert(role, cn, sans, alt_names, mount = 'pki', ttl = '365d')
      Mash.new(
        Vault.logical.write(
          "/#{mount}/issue/#{role}",
          common_name: cn,
          ip_sans: sans,
          alt_names: alt_names,
          ttl: ttl
        ).data
      )
    end
  end

  def openbao
    @openbao ||= Openbao::Client.new(node)
  end
end

Chef::Recipe.include(Openbao)
Chef::Resource.include(Openbao)
