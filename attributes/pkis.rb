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
          'pg-common.db.east.local',
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
  },
  "pki-k8s" => {
    mount: 'pki-k8s',
    default_lease_ttl: '365d',
    max_lease_ttl: '8000d',

    roles: {
      apiserver: {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [
          'kube-apiserver',
          '*.cp.east.local',
          'kubernetes.default.svc.cluster.local',
          'kubernetes.default.svc',
          'kubernetes.default',
          'kubernetes',
          'cp.east.local',
        ],
        organization: 'system:apiserver',
        allow_localhost: true,
        allow_bare_domains: true,
      },
      "cp-kubelet" => {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [

          '*.cp.east.local',
          'system:node:01.cp.east.local',
          'system:node:01.cp.east.local',
          'system:node:01.cp.east.local',
        ],
        organization: 'system:nodes',
        allow_localhost: true,
        allow_bare_domains: true,
        enforce_hostnames: false,
        allow_glob_domains: true,
      },         
      "kubelet" => {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [
          '*.kubelet.east.local',
          'system:node:01.kubelet.east.local',
          'system:node:01.kubelet.east.local',
          'system:node:01.kubelet.east.local',
        ],
        organization: 'system:nodes',
        allow_localhost: true,
        allow_bare_domains: true,
        enforce_hostnames: false,
        allow_glob_domains: true,
      },
      masters: {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [
          'kube-apiserver-kubelet-client',
          'system:kube-controller-manager',
          'system:kube-scheduler',
          'bpolozov' # мой юзер, можно отдельный pki с админами кластера
        ],
        organization: 'system:masters',
        allow_localhost: true,
        enforce_hostnames: false,
        allow_bare_domains: true,
      },
      etcd: {
        ttl: '365d',
        max_ttl: '4000d',
        allowed_domains: [
          '01.cp.east.local',
          '02.cp.east.local',
          '03.cp.east.local',
        ],
        organization: 'etcd',
        allow_localhost: true,
        allow_bare_domains: true,
      },
    }
  }
}
