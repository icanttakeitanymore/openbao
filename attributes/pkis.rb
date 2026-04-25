default['openbao']['pki'] = {
  "pki-ns" => {
    mount: 'pki-ns',
    default_lease_ttl: '365d',
    max_lease_ttl: '8000d',

    roles: {
      ns: {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [
          'ns1.east.local',
          'ns2.east.local',
          'ns3.east.local',
          'ns.east.local',
        ],
        allow_localhost: true
      }
    }
  },
  "pki-pg-common" => {
    mount: 'pki-pg-common',
    default_lease_ttl: '365d',
    max_lease_ttl: '8000d',

    roles: {
      main: {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [
          '01.pg-common.east.local',
          '02.pg-common.east.local',
          '03.pg-common.east.local',
          'pg-common.east.local',
          'patroni',
          'replication',
          'barman',
          'bpolozov',
          'pdns',
        ],
        allow_localhost: true
      }
    }
  }
}