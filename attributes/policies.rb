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
}

default['openbao']['policies_actions'] = {
  common: :create,
  ns: :create,
  "pg-common" => :create,

}
