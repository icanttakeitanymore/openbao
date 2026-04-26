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
          '01.pg-common.db.east.local',
          '02.pg-common.db.east.local',
          '03.pg-common.db.east.local',
          'pg-common.east.local',
          'patroni',
          'replication',
          'barman',
          'bpolozov',
        ],
        allow_localhost: true,
        allow_bare_domains: true,
      },
      pdns: {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [
          'pdns'
        ],
        allow_localhost: true,
        allow_bare_domains: true,
      },
      cinc: {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [
          'cinc'
        ],
        allow_localhost: true,
        allow_bare_domains: true,
      }
    }
  }
}