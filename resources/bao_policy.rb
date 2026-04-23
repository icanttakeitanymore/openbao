resource_name :bao_policy
provides :bao_policy

# Свойства ресурса
property :policy_name, String, name_property: true
property :rules, [Hash], required: false

action :create do
  client = openbao
  name   = new_resource.policy_name

  # Получаем объект Vault::Policy
  current_policy_obj = client.read_policy(name)

  # Парсим существующие правила в Hash для сравнения
  # Если политики нет, текущий хэш будет пустым
  current_hash = if current_policy_obj && !current_policy_obj.rules.empty?
                   begin
                     JSON.parse(current_policy_obj.rules)
                   rescue JSON::ParserError
                     # Если в Bao вдруг лежит HCL, принудительно обновляем на наш JSON
                     {}
                   end
                 else
                   {}
                 end

  # Сравниваем хэши напрямую
  if current_hash != new_resource.rules
    converge_by("update policy #{name} with new JSON rules") do
      client.write_policy(name, JSON.generate(new_resource.rules))
    end
  else
    Chef::Log.info("Policy #{name} is already up to date")
  end
end

action :delete do
  client = openbao
  name   = new_resource.policy_name

  if client.read_policy(name)
    converge_by("delete policy #{name}") do
      # Используем стандартный метод удаления политик из sys API
      client.delete_policy(name)
    end
  else
    Chef::Log.info("Policy #{name} already absent")
  end
end

action_class do
  include Openbao
end
