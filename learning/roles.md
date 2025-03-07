# Chef Roles

## What is a Role?

- In your organization, if your infrastructure grows to meet the demands of higher traffic, there are likely to be
  multiple, redundant servers that all perform the same basic tasks.nFor instance, these might be web servers that a
  load balancer passes requests to. They would all have the same basic configuration and could be said to each satisfy
  the same "role."
- **Chef's view of roles is almost entirely the same as the regular definition. A role in chef is categorization that
  describes what a specific machine is supposed to do. What responsibilities does it have and what software and settings
  should be given to it.**
- In different situations, you may have certain machines handling more than one role, for instance, if you are testing
  your software, one server may include the database and web server components, while in production, you plan on having
  these on separate servers.
- *With chef, this can be as easy as assigning the first server to both roles and then assigning each role to separate
  servers for your production machines.*
- Each role will contain the configuration details necessary to bring the machine to a fully operational state to
  fulfill its specific role. This means you can gather cookbooks that will handle package installations, service
  configurations, special attributes for that role, etc.

## What is Environment

- **An environment is simply a designation meant to help an administrator know what stage of the production process a
  server is a part of. Each server can be part of exactly one environment.**
- *By default, one environment called `_defalut` is created. Each node will be placed into this environment unless
  another environment is specified. Environments can be created to tag a server as part of a process group.*
- For instance, one environment may be called `testing` and another may be called `production`. Since you don't want any
  code that is still in testing on your production machines, each machine can only be in one environment.
- You can then have one configuration for your machines in your testing environment, and completely different
  configuration for computers in production.
- Environments also help with the testing process itself. You can specify that in production, a cookbook should be a
  stable version. However, you can specify that if a machine is part of the testing environment, it can receive a more
  recent version of the cookbook.

## How to use Roles

### Create a Role using Ruby DSL

- We can create roles using the `roles` directory in our `chef-repo` directory on our workstation.
- `cd ~/chef-repo/roles`
- Within this directory, we can create different files that define the roles we want in our organization. Each role file
  can be written either in Chef's Ruby DSL or in JSON.
- Let create a role for our web server
- `vim web_server.rb`
- Inside this file we can begin by specifying some basic data about the role.
  ```
  name "web_server"
  description "A role to configure our front-line web servers"
  ```
- These should be fairly straight forward.
- The `name` that we give cannot contain spaces and should generally match the file name we selected for this role,
  minus the extension.
- The `description` is just a human-readable message about what the role is supposed to manage.
- Next, we can specify the `run_list` that we wish to use for this specific role. The run_list of a role can contain
  cookbooks (which will run the default recipe), recipes from cookbooks (as specified using the cookbook::recipe
  syntax), and other roles.
- *The run_list will always be executed sequentially, so put the dependency items before the other items.*

  ```
  name "web_server"
  description "A role to configure our front-line web servers"
  run_list "recipe[apt]", "recipe[nginx]"
  ```
- We can also use environment-specific run_list to specify variable configuration changes depending on which environment
  a server belongs to.
- For instance, if a node is in the `production` environment, you could want to run a special recipe in your `nginx`
  cookbook to bring that server up to the production policy requirements. You could also have a recipe in nginx cookbook
  meant to configure special changes for testing servers.
  ```
  name "web_server"
  description "A role to configure our front-line web servers"
  run_list "recipe[apt]", "recipe[nginx]"
  env_run_lists "production" => ["recipe[nginx::config_prod]"], "testing" => ["recipe[nginx::config_test]"]
  ```
- In the above example, we have specified that if the node is part of the production environment, it should run the
  `config_prod` recipe within nginx cookbook. However, if the node is in the testing environment, it will run the
  `config_test` recipe. If a node is in a different environment, then the default run_list will be applied.
- Similarly, we can specify default and override attributes. You should be familiar with default attributes at this
  point. In our roles, we can set default attributes which can override any part of the default attributes set anywhere
  else.
  ```
  name "web_server"
  description "A role to configure our front-line web servers"
  run_list "recipe[apt]", "recipe[nginx]"
  env_run_lists "production" => ["recipe[nginx::config_prod]"], "testing" => ["recipe[nginx::config_test]"]
  override_attributes "nginx" => { "gzip" => "on" }
  ```

### Create a role using JSON

- The other format that can be used to configure roles is JSON. In fact, we can explore this formast using knife to
  automatically create a role in this format. Let's create a test role:
- `knife role create test`
- The role will look something like below

```
{
  "unsme": "test",
  "description": "",
  "json_class": "Chef::Role",
  "default_attributes": {
  }
  "override_attributes": {
  },
  "chef_type": "role",
  "run_list": [
  ],
  "env_run_list":{
  }
}

```

- This is the same information that we entered into the Ruby DSL-formatted file. The only differences are the formatting
  and the addition of the two new keys called `json_class` and `chef_type`.
- The below role in JSON format which is similar to the one that we have created using the Ruby DSL.

  ```
  {
    "name": "web_server",
    "description": "A role to configure frontline web-servers",
    "json_class": "Chef::Role",
    "default_attributes": {
      "nginx":{
        "log_location": "/var/log/nginx.log"
      }
    }
    "override_attributes": {
      "nginx": {
        "gzip": "on"
      }
    },
    "chef_type": "role",
    "run_list": [
      "recipe[apt]",
      "recipe[nginx]"
    ],
    "env_run_lists": {
      "production": [
        "recipe[nginx:config_prod]"
      ],
      "testing": [
        "recipe["nginx:config_test"]"
      ]
    }
  }
  ```

## Transferring the roles between Workstation to Server

- When we save a JSON file created using Chef command, the role is created on the server. In contrast, our Ruby file
  that we created locally is not uploaded to the server.
- We can upload the ruby file to the server by running a command as follows
    - `knife role from file </path/to/the/role/file>`
- This will upload our role information specified in our file to the server. This would work with either Ruby DSL
  formatted file or JSON file.
- In the similar way, we can get the role from the server using the knife command, as follows
    - `knife role show web_server -F json > </path/to/save/role>`

## Assigning Roles to Nodes

- So now regardless of the format we used, we can have our role on the chef server, How do we assign a node with a
  certain role?
- We assign a role to a node just as we would a recipe, in the node's run list.
- So to add our role to a node, we would find the node by using the below command
    - `knife node list`
    - `knife node edit <node_name>`
- This will bring up the node definition file, which will allow us to update the run_list with the role.

  ```
  {
    "name": "client1",
    "chef_environment": "_default",
    "normal": {
      "tags": [
      ]
    },
    "run_list": [
      "recipe[nginx]"
    ]
  }
  ```

- Now, we will be going to update the node run_list with our newly created role.

  ```
  {
    "name": "client1",
    "chef_environment": "_default",
    "normal": {
      "tags": [
      ]
    },
    "run_list": [
      "role[web_server]"
    ]
  }
  ```
- This will perform the same steps as our previous recipes, but instead it will simply speaks to the role that the
  server should have.
- This allows us to access all the servers in a specific role by search. For instance you could search for all the
  database servers in the production environment by searching a role and environment.
    - `knife search "role:dstabase_servers AND chef_environment:production" -a node`
- This will give us a list of nodes that are configured as the database servers. You can use this internally in
  cookbooks to configure webservers to automatically add all the production database servers to its pool to make read
  requests from.

## How to use Environments

### Creating an Environment

- In some ways, environments are fairly similar to roles. They are also used to differentiate different servers, but
  differentiate by the function of the servers, environments differentiate by the phase of development that the machine
  belongs to.
- Environments that coincide with your actual production life cycle make the most sense. If you run your code through
  testing, staging, and production, you should have environments to match.
- As with roles, we can set up the definition files either in the Ruby DSL or in JSON. In our "chef-repo" directory on
  our workstation, we should have an environments directory. This is where we should put our environment files.