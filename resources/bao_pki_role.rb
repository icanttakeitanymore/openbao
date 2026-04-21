resource_name :bao_pki_role
provides :bao_pki_role

property :mount, String, default: 'pki'
property :role_name, String, name_property: true

property :allowed_domains, Array, default: []
property :allow_subdomains, [true, false], default: true
property :allow_localhost, [true, false], default: true
property :allow_any_name, [true, false], default: false
property :allow_bare_domains, [true, false], default: true
property :ttl, String, default: '365h'
property :max_ttl, String, default: '4000h'

action :create do
  client = openbao
  mount = new_resource.mount
  name  = new_resource.role_name

  current = client.pki_role(mount, name)

  desired = {
    allowed_domains: new_resource.allowed_domains,
    allow_subdomains: new_resource.allow_subdomains,
    allow_any_name: new_resource.allow_any_name,
    allow_localhost: new_resource.allow_localhost,
    allow_bare_domains: new_resource.allow_bare_domains,
    ttl: client.duration_to_seconds(new_resource.ttl),
    max_ttl: client.duration_to_seconds(new_resource.max_ttl),

  }

  if client.normalize_role(current) != client.normalize_role(desired)
    converge_by("create/update PKI role #{name} at #{mount}") do
      client.write_pki_role(mount, name, **desired)
    end
  else
    Chef::Log.info("PKI role #{name} already up to date")
  end
end

action :delete do
  client = openbao
  mount = new_resource.mount
  name  = new_resource.role_name

  if client.pki_role(mount, name)
    converge_by("delete PKI role #{name} at #{mount}") do
      Vault.logical.delete("#{mount}/roles/#{name}")
    end
  else
    Chef::Log.info("PKI role #{name} already absent")
  end
end

action_class do
  include Openbao
end
