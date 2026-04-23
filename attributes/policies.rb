default['openbao']['policies'] = {
  common: {
    path: {
      'common/*' => {
        capabilities: ['read','update', 'list']
      },
    }
  }
}

default['openbao']['policies_actions'] = {
  common: :create
}
