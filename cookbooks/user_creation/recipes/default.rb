#
# Cookbook:: user_creation
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

group_name = node['user_creation']['group_name']
users = node['user_creation']['users']

# create unix group
group group_name do
  action :create
end

# create unix users
users.each do |user|
  user user do
    group group_name
    shell '/bin/bash'
    home "/home/#{user}"
    manage_home true
    action :create
  end
end

# set password expire policy
users.each do |user|
	execute "Set password policy for #{user}" do
		command "chage --mindays 7 --maxdays 90 --warndays 7 #{user}"
		action :run
	end
end
