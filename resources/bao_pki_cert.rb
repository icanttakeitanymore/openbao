resource_name 'bao_pki_cert'
provides 'bao_pki_cert'

require 'chef/resource'

property :cn, String, desired_state: false
property :mount, String, desired_state: false, default: 'pki'
property :role, String, desired_state: false
property :owner, String, default: 'root'
property :group, String, default: 'root'
property :ip_sans, String, desired_state: false, default: ''
property :alt_names, String, desired_state: false, default: ''
property :chain, [true, false], desired_state: false, default: true
property :issuing_ca, String, desired_state: false, required: false
property :certificate, String, desired_state: false, required: true
property :private_key, String, desired_state: false, required: true
property :ttl, String, default: '365d'
property :mode, [String, Integer], coerce: proc { |m| m.is_a?(Integer) ? m.to_s(8) : m }, default: '0644'

default_action :create

load_current_value do |new_resource|
  current_value_does_not_exist! if ENV["BAO_FORCE_CERT_ISSUE"]
  if new_resource.mode.length == 3
    new_resource.mode = '0' + new_resource.mode
  end
  if ::File.exist?(certificate) && ::File.exist?(private_key)
    old_mode = ::File.stat(new_resource.private_key).mode & 07777
    cn get_cn(certificate)
    role role
    chain chain
    mode sprintf("%04o", old_mode)
    owner ::Etc.getpwuid(::File.stat(new_resource.private_key).uid).name
    group ::Etc.getgrgid(::File.stat(new_resource.private_key).gid).name
  else
    current_value_does_not_exist!
  end
  if get_days(certificate) < Time.now + 86400 * 30
    current_value_does_not_exist!
  end
end

def get_cn(path)
  cert = OpenSSL::X509::Certificate.new(::File.read(path))
  subj = cert.subject.to_s
  return subj.scan(/CN=(.+?(?=\/|\z))/)[0][0]
end

def get_days(path)
  cert = OpenSSL::X509::Certificate.new(::File.read(path))
  return cert.not_after
end

action :create do
  converge_if_changed do
    response = openbao.pki_cert(new_resource.role, new_resource.cn, new_resource.ip_sans, new_resource.alt_names,
                                new_resource.mount, new_resource.ttl)

    cert = case new_resource.chain
           when true
             unless response['ca_chain'].nil?
               response['certificate'] + "\n" + response['ca_chain'].join("\n")
             else
               Chef::Log.warn "bao_pki_cert: chain true, but pki has no chain"
             end
           when false
             response['certificate']
           end

    file new_resource.certificate do
      action :create
      content cert
      owner  new_resource.owner
      group  new_resource.group
      mode   new_resource.mode
    end
    file new_resource.private_key do
      action :create
      content response['private_key']
      owner  new_resource.owner
      group  new_resource.group
      mode   new_resource.mode
      sensitive true
    end
    if property_is_set?(:issuing_ca) && !response['issuing_ca'].nil? && response['ca_chain'].nil?
      file new_resource.issuing_ca do
        action :create
        content response['issuing_ca']
        owner  new_resource.owner
        group  new_resource.group
        mode   new_resource.mode
        sensitive false
      end
    end
    if property_is_set?(:issuing_ca) && !response['ca_chain'].nil?
      file new_resource.issuing_ca do
        action :create
        content response['ca_chain'].join("\n")
        owner  new_resource.owner
        group  new_resource.group
        mode   new_resource.mode
        sensitive false
      end
    end
  end
end

action_class do
  include Openbao
end
