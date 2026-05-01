default['openbao']['policies'] = {
  common: {
    path: {
      'common/*' => {
        capabilities: ['read', 'update', 'list']
      },
    }
  },
  ns: {
    path: {
      'pki-pg-common/issue/pdns' => {
        capabilities: ['read', 'update']
      },
      'ns/*' => {
        capabilities: ['read', 'update', 'list']
      },
    },
  },
  cinc: {
    path: {
      'pki-pg-common/issue/cinc' => {
        capabilities: ['read', 'update']
      },
      'cinc/*' => {
        capabilities: ['read', 'update', 'list']
      },
    },
  },
  "pg-common" => {
    path: {
      'pki-pg-common/issue/main' => {
        capabilities: ['read', 'update']
      },
      'ns/*' => {
        capabilities: ['read', 'update', 'list']
      },
    },
  },
  "k8s-cp" => {
    path: {
      'pki-k8s/issue/apiserver' => {
        capabilities: ['read', 'update']
      },
      'pki-k8s/issue/masters' => {
        capabilities: ['read', 'update']
      },
      'pki-k8s/issue/etcd' => {
        capabilities: ['read', 'update']
      },
      'pki-k8s/issue/nodes' => {
        capabilities: ['read', 'update']
      },
      'pki-k8s/issue/cp-kubelet' => {
        capabilities: ['read', 'update']
      },
      'k8s/*' => {
        capabilities: ['read', 'update', 'list']
      },
    },
  },
  "k8s-kubelet" => {
    path: {
      'pki-k8s/issue/nodes' => {
        capabilities: ['read', 'update']
      },
      'k8s/*' => {
        capabilities: ['read', 'update', 'list']
      },
    },
  },
}

default['openbao']['policies_actions'] = {
  common: :create,
  ns: :create,
  "pg-common" => :create,
  "k8s-cp" => :create,
  "k8s-kubelet" => :create,
}
