node['openbao']['pki'].each do |mount_name, mount_data|
  bao_pki mount_data[:mount] do
    default_lease_ttl mount_data[:default_lease_ttl]
    max_lease_ttl mount_data[:max_lease_ttl]
    root_common_name mount_name
    action :create
  end

  mount_data[:roles].each do |role_name, role_data|
    bao_pki_role role_name do
      mount mount_data[:mount]
      ttl role_data[:ttl]
      max_ttl role_data[:max_ttl]
      allowed_domains role_data[:allowed_domains]
      allow_localhost role_data[:allow_localhost]
      action :create
    end
  end
end
