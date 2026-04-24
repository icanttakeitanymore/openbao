default['openbao']['nodes'] = %w(
  01.vault.east.local
  02.vault.east.local
  03.vault.east.local
)

default['openbao']['vip_hostname'] = 'vault.east.local'

default['openbao']['bootstrap']['auto_init'] = true
default['openbao']['bootstrap']['init_host'] = "01.vault.east.local"

# you don't need more if after people leave your team you don't rekey vault.
# you sould do it, but you won't. but you shouldn't if it's a lab.
default['openbao']['bootstrap']['secret_shares'] = 1
default['openbao']['bootstrap']['secret_threshold'] = 1

# unseal_key and root_token will be thrown into
# node['openbao']['bootstrap']['secret'] + 'bootstrap' after init.
# throw them on fs to 02 and 03 nodes by hand unseal timer will unseal them or do manually.
# anyway while chef-to-vault auth integration is not done
# you will need root token for many things on node, like pki init and so on
# later you can drop them or unseal manually.

default['openbao']['unseal_key_path'] = '/etc/openbao/unseal_key'
default['openbao']['token_path'] = '/etc/openbao/root_token'

default['openbao']['bootstrap']['secret'] = 'bao'
default['openbao']['bootstrap']['pki_mount'] = 'bao-pki' # oh fuck, fuck, fuck with vault-0.18.2. (it can be undersored of course)
default['openbao']['bootstrap']['pki_role'] = 'bao'

# after the run put /etc/openbao/ca.pem into your system ca bundle
# or make new pki.

default['openbao']['chef-vault-auth-plugin']['url'] =
  'https://github.com/icanttakeitanymore/chef-vault-auth-plugin/releases/download/v2026.04.23-2/chef-vault-auth-plugin'
default['openbao']['chef-vault-auth-plugin']['sha256'] =
  '7f0f126b1edff3a2bd8dc89f436e13f910dc472b1c40c68cb9272739633f50a9'
