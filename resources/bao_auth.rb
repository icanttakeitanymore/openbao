resource_name :bao_auth
provides :bao_auth
property :path, String, name_property: true
property :type, String, required: true
property :description, String, default: 'managed by chef'
property :config, Hash, default: {}

action :enable do
  client = openbao
  path = new_resource.path

  unless client.auth_exists?(path)
    converge_by("enable auth #{new_resource.type} at #{path}") do
      client.enable_auth(path, new_resource.type, new_resource.description)
    end
  end

  unless new_resource.config.empty?
    current = client.read_auth_config(path) || {}

    if current != new_resource.config
      converge_by("configure auth #{path}") do
        client.write_auth_config(path, new_resource.config)
      end
    end
  end
end

action :disable do
  client = openbao
  path = new_resource.path

  if client.auth_exists?(path)
    converge_by("disable auth at #{path}") do
      client.disable_auth(path)
    end
  else
    Chef::Log.info("Auth #{path} already disabled")
  end
end

action_class do
  include Openbao
end
