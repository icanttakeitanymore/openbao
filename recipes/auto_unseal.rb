template '/usr/local/bin/openbao-unseal.sh' do
  source 'openbao-unseal.sh.erb'
  variables(
    schema: openbao.tls_enabled? ? 'https' : 'http'
  )
  owner 'root'
  group 'root'
  mode '0750'
end

systemd_unit 'openbao-unseal.service' do
  content({
            Unit: {
              Description: 'OpenBao auto-unseal job',
              Requires: 'openbao.service',
              After: 'openbao.service',
              PartOf: 'openbao.service'
            },
            Service: {
              Type: 'oneshot',
              ExecStart: '/usr/local/bin/openbao-unseal.sh'
            }
          })
  action [:create, :enable]
end

systemd_unit 'openbao-unseal.timer' do
  content({
            Unit: {
              Description: 'OpenBao unseal timer',
              BindsTo: 'openbao.service',
              After: 'openbao.service',
              PartOf: 'openbao.service'
            },
            Timer: {
              OnBootSec: '30',
              OnUnitActiveSec: '60',
              AccuracySec: '10',
              Unit: 'openbao-unseal.service'
            },
            Install: {
              WantedBy: 'openbao.service'
            }
          })
  action [:create, :enable, :start]
end
