#
# Cookbook:: password_rotation
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Accessing the databag data

users = data_bag_item("users", "data")["users"]
group_name = data_bag_item("users", "data")["group_name"]


# creating a unix group using chef resource
group group_name do
    action :create


# creating users using chef user resource
users.ech do |user|
    user user.name do
        group group_name
        password user.password
        home "/home/${user.name}"
        shell "/bin/bash"
        action :create
    end
end

# set password expiry using chef resource
users.each do |user|
    execute "enabling password expiry" do
        command "chage --mindays 7 --maxdays 90 --warndays 7 ${user.name}"
    end
end