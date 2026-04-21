resource_name :bao_init
provides :bao_init

property :secret_shares, Integer, required: true
property :secret_threshold, Integer, required: true
property :unseal_key_path, String, required: true
property :token_path, String, required: true
property :secret, String, required: true

default_action :run

action :run do
  converge_by("Initialize OpenBao") do
    client = openbao

    # 1. already initialized?
    if client.initialized?
      Chef::Log.info("Vault already initialized")
      if client.read(new_resource.secret, "bootstrap").nil?
        client.store_bootstrap_secret(
          new_resource.secret,
          "bootstrap",
          {
            unseal_keys: openbao.read_local_unseal_keys(new_resource.unseal_key_path),
            root_token: openbao.read_local_token(new_resource.token_path)
          }
        )
      end
    else
      openbao.wait_for_health_ready(timeout: 180)
      Chef::Log.info("Initializing Vault")

      result = client.init(
        secret_shares: new_resource.secret_shares,
        secret_threshold: new_resource.secret_threshold
      )

      keys  = result.keys_base64
      token = result.root_token

      client.write_local_secrets(
        keys,
        token,
        new_resource.unseal_key_path,
        new_resource.token_path
      )

      client.unseal(keys)
      # here may something go wrong
      openbao.wait_for_raft_ready(timeout: 180)
      client.setup!
      # store in bao mount
      client.store_bootstrap_secret(
        new_resource.secret,
        "bootstrap",
        {
          unseal_keys: keys,
          root_token: token
        }
      )
    end

    # 2. ensure unsealed using local file
    keys = client.read_local_unseal_keys(new_resource.unseal_key_path)

    if keys.empty?
      Chef::Log.warn("No unseal keys found at #{new_resource.unseal_key_path}")
    elsif client.sealed?
      Chef::Log.info("Unsealing Vault from file")
      client.unseal(keys)
    end

    # 3. ensure token usable
    token = client.read_local_token(new_resource.token_path)
    if token
      Vault.token = token
    else
      Chef::Log.warn("No root token file found")
    end
  end
end

action_class do
  include Openbao
end
