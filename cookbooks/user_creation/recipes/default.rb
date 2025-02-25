#
# Cookbook:: user_creation
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# create unix group
group node['user_creation']['group_name'] do
  action :create
end

create unix users
node['user_creation']['users'].each do |user|
  user user do
    group node['user_creation']['group_name']
    shell '/bin/bash'
    home "/home/#{user}"
    action :create
  end
end
