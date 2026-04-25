VAULT_NODES = {
  '01.vault.east.local' => '192.168.5.11',
  '02.vault.east.local' => '192.168.5.12',
  '03.vault.east.local' => '192.168.5.13'
}

node_ip = VAULT_NODES[node['fqdn']]

override['frr'] = {
  'bgp_groups' => {
    'vault_service' => {
      'router_id' => node_ip,
      'local_as' => 65001,

      'advertised_prefixes' => [
        '10.100.0.100/32'
      ],

      'neighbors' => [
        {
          'ip' => '192.168.5.1',
          'remote_as' => 65000,
          'description' => 'core-router',
          'bfd' => true
        }
      ],

      'service_tracking' => {
        'enabled' => true,
        'healthcheck' => '/v1/sys/health',
        'bind_interface' => 'dummy0'
      },

      'timers' => '3000 3',

      'multipath' => true
    }
  }
}

default['frr']['dummies'] = {
  'ifaces' => {
    'dummy0' => {
      address: '10.100.0.100/32',
      url: "https://#{node[:fqdn]}:443/v1/sys/health",
      status_codes: [200, 429],
      fail: 3,
      raise: 1,
      interval: 1000,
      timeout: 1000
    }
  },

  'ifaces_actions' => {
    'dummy0' => :create
  }
}