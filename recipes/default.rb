include_recipe 'common'

cookbook_file '/etc/apt/keyrings/openbao.gpg' do
  source 'keyrings/openbao.gpg'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

apt_repository 'openbao' do
  uri          'https://pkgs.openbao.org/deb/'
  distribution 'stable'
  components   ['main']
  signed_by '/etc/apt/keyrings/openbao.gpg'
end

%w(openbao).each do |pkg|
  package pkg do
    action :install
  end

  service pkg do
    action :nothing
  end

  user pkg do
    shell '/usr/sbin/nologin'
  end
end

directory '/etc/openbao/' do
  owner 'openbao'
  group 'openbao'
  mode '0755'
  action :create
end

include_recipe 'openbao::setup'
include_recipe 'openbao::auto_unseal'
