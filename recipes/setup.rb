schema = openbao.tls_enabled? ? 'https' : 'http'
file '/etc/openbao/openbao.env'

template '/etc/openbao/openbao.hcl' do
  source 'bootstrap/openbao.hcl.erb'
  variables(
    nodes: node['openbao']['nodes'],
    tls_enabled: openbao.tls_enabled?,
    schema: schema
  )
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[openbao]', :immediately
end

service 'openbao' do
  action [:enable, :start]
end

allowed_domains = [node['openbao']['vip_hostname']]
allowed_domains += node['openbao']['nodes']
allowed_domains += ['localhost']

if node['fqdn'] == node['openbao']['bootstrap']['init_host']
  if node['openbao']['bootstrap']['auto_init']
    bao_init 'initialize' do
      secret_shares node['openbao']['bootstrap']['secret_shares']
      secret_threshold node['openbao']['bootstrap']['secret_threshold']
      unseal_key_path node['openbao']['unseal_key_path']
      token_path node['openbao']['token_path']
      secret node['openbao']['bootstrap']['secret']
    end
  end

  bao_pki node['openbao']['bootstrap']['pki_mount'] do
    default_lease_ttl '365d'
    max_lease_ttl '8000d'
    action :create
  end

  bao_pki_role node['openbao']['bootstrap']['pki_role'] do
    mount node['openbao']['bootstrap']['pki_mount']
    ttl '365d'
    max_ttl '4000d'
    allowed_domains allowed_domains
    allow_localhost true
    action :create
  end
end

bao_pki_cert 'bao-cert' do
  cn node['fqdn']
  mount node['openbao']['bootstrap']['pki_mount']
  role node['openbao']['bootstrap']['pki_role']

  ip_sans node['ipaddress'] + ',127.0.0.1,10.100.0.100'
  alt_names allowed_domains.join(',')

  certificate '/etc/openbao/cert.pem'
  private_key '/etc/openbao/key.pem'
  issuing_ca '/etc/openbao/ca.pem'
  owner 'openbao'
  group 'openbao'
  mode '0644'

  ttl '365d'
  notifies :reload, "service[openbao]", :delayed
  notifies :reload, "service[envoy]", :delayed
end


service 'envoy' do
  action :nothing
end