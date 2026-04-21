resource_name :bao_pki
provides :bao_pki

property :path, String, name_property: true
property :max_lease_ttl, String, default: '8000d'
property :default_lease_ttl, String, default: '365d'
property :generate_root, [TrueClass, FalseClass], defautl: true
property :root_type, String, default: "exported"
property :root_ttl, String, default: "8000d"
property :root_common_name, String, default: "bao-pki"
property :root_opts, Hash, default: {}
action :create do
  client = openbao
  path = new_resource.path.sub(%r{/$}, '')

  # 1. Ensure mount exists
  unless client.mount_exists?(path)
    converge_by("enable PKI mount at #{path}") do
      client.enable_pki(path, max_lease_ttl: new_resource.max_lease_ttl)
    end
  end

  # 2. Fetch current tune state
  current = client.get_mount_tune(path).to_h || {}

  desired_default = client.duration_to_seconds(new_resource.default_lease_ttl)
  desired_max     = client.duration_to_seconds(new_resource.max_lease_ttl)

  current_default = current[:default_lease_ttl]
  current_max     = current[:max_lease_ttl]

  # 3. Tune only if drift detected
  if current_default != desired_default || current_max != desired_max
    converge_by("tune PKI mount #{path} (default=#{desired_default}, max=#{desired_max})") do
      client.tune_mount(path, {
                          default_lease_ttl: desired_default,
                          max_lease_ttl: desired_max
                        })
    end
  end
  unless client.pki_root_exists?(new_resource.path)
    converge_by("generate PKI root") do
      client.generate_root(
        new_resource.path,
        common_name: new_resource.root_common_name,
        ttl: new_resource.root_ttl,
      )
    end
  end
end

action :delete do
  client = openbao
  path = new_resource.path.sub(%r{/$}, '')

  # 1. Only unmount if it exists
  if client.mount_exists?(path)
    converge_by("unmount PKI mount at #{path}") do
      client.unmount(path)
    end
  else
    Chef::Log.info("PKI mount #{path} already absent, skipping")
  end
end

action_class do
  include Openbao
end
