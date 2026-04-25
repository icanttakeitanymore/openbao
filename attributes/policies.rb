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
      'pki-pg/issue/pg_cs' => {
        capabilities: ['read', 'update']
      },
      'ns/*' => {
        capabilities: ['read', 'update', 'list']
      },
    },
  },
  "pg-common" => {
    path: {
      'pki-pg/issue/pg_cs' => {
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
