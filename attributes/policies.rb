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
      'pki-ns/issue/ns' => {
        capabilities: ['read', 'update']
      },
      'ns/*' => {
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
