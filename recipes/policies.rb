node['openbao']['policies'].each do |policy_name, rules_data|
  bao_policy policy_name do
    rules rules_data.to_h
    action node['openbao']['policies_actions'][policy_name]
  end
end
