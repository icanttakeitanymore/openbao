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
  }
}