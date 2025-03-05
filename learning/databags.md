# Chef Data Bags

- Data bags store global variables as JSON data. Data bags are indexed for searching and can be loaded by a cookbook or
  accessed during search.

## create a Data Bag

- To create a data bag, we have two ways: using knife commandline or manual way. The recommended way is to create with
  knife, but as long as the data bag folders and item JSON files are created correctly, either method is safe and
  effective.

## creating a Data Bag with knife

- Use the `knife data bag create` command to create data bags and data bag items.
    - `knife data bag create <DATA_BAG_NAME> <DATA_BAG_ITEM>`
- We can we the `from file` argument to update data bag items
    - `knife data bag from file <BAG_NAME> <ITEM_NAME>.json`
- As long as the file is in the correct directory structure knife will be able to find the data bag and data bag item
  with only the name of the data bag and data bag item
    - `knife data bag from file <BAG_NAME> <ITEM_NAME>.json` will load the `data_bags/<BAG_NAME>/<ITEM_NAME>.json`.

# creating Data Bag manually

- One or more data bags and data bag items can be created manually under the `data_bags` directory in chef repo.
  Consider the below example
- `mkdir data_bags/admins` it will create a data bag folder named `admins` which is equivalent to the command
  `knife data bag  create admins`
- A data bag item can be created manually in the same way as the data bag, but by also specifing the file name for data
  bag item
    - `touch data_bags/admins/charlie.json` which is equivalent to `knife data bag create admins charlie`

## Data bag items

- A data bag is a container of related data bag items, where each individual data bag item is a JSON file.
- knife can load a data bag item by specifying the name of the data bag to which the item belongs and then the filename
  of the data bag item.
- The only structural requirement of data bag item is that it must hav ana `id:`
    ```
    {
    
    /* This is a supported comment */
    // This style is also supported
    
    "id": "ITEM_NAME",
    "key": "value"
    
    }    
    ```
- where, the `key` and `value` are the key value pair of each additional attribute within the data bag item.

## Encrypting a data bag item

- A data bag item can be encrypted using shared secret encryption. This allows each data bag item to store confidential
  information ot to manage in a source control system.
- Each data bag item may be encrypted individually; if a data bag contains multiple encrypted data bag items, these data
  bag items aren't required to share the same encrypted keys.
    ```
    NOTE:
    Because the contents of encrypted data bag items aren't visible to the Chef Infra Server, search queries aganish data bags with encrypted items won't return any results. 
    ```

### Knife Options

- knife can encrypt and decrypt data bag items when the `knife data bag` subcommand is run with `create`, `edit`,
  `from file` or `show` arguments and the following options.
    - `--secret <SECRET>` => The encryption key that's used for values contained within a data bag item. If `secret`
      isn't specified, Chef Infra Client looks for a secret at the path specified by the `encrypted_data_bag_secret`
      setting in the `client.rb` file
    - `--secret-file <FILE>` => the path to the file contains the encryption key.

### Secret Keys

- Encrypting a data bag item requires a secret key. A secret key can be created in any number of ways. For example,
  OpenSSL can be used to generate a random number, which can be used as the secret key:
    - `openssl rand -base64 512 | tr -d '\r\n' > encrypted_data_bag_secret`
- Where the `encrypted_data_bag_secret` is the name of the file which will contain the secret key.

### Encrypt

- A data bag item can be encrypted using a knife command similar to
    - `knife data bag create passwords mysql --secret-file /tmp/my_data_bag_key`
- Where `passwords` is the name of the databag, `mysql` is the name of the data bag item, and `/tmp/my_data_bag_key` is
  the path to the location in which the file that contains the secret-key is located.

### Verify Encryption

- When the contents of the data bag item are encrypted, they won't be able to be readable until they're decrypted.
  Encryption can be verified with a knife command similar to:
    - `knife data bag show passwords mysql`

### Decrypt

- AN encrypted data bag item is decrypted with a knife command similar to
    - `knife data bag show --secret-file /tmp/my_data_bag_key passwords mysql`

### Edit data bag item

- A data bag can be edited in two ways: using knife or by using the chef management console

#### Edit a data bag with knife

- Use the `edit` argument to edit the data contained in a data bag. If encryption is being used, the data bag will be
  decrypted, the data will be made available in the $EDITOR, and encrypted again before saving it to the Chef Infra
  Server.
- To edit an item named `charlie` that is contained in a data bag named `admins`, we can use the below command
    - `knife data bag edit admins charlie`

## Use Data Bags

Data bags can be accessed in the following ways:

### Search

- Data bags store global variables as JSON data. Data bags are indexed for searching and can be loaded by a cookbook or
  accessed during search.
- Any search for data bag (or data bag item) must specify the name of the data bag and then provide the search query
  string that will be used during the search.
- For example, to use search within a data bag named `admin_data` across all items, except for the `admin_users` item,
  enter the following  
  `knife search admin_data "(NOT id:admin_users)"`
- To include same search query in a recipe, use a code block similar to:  
  `search(:admin_data, 'NOT id:admin_users')`
- It may not be possible to know which data bag items will be needed. It may be necessary to load everything in a data
  bag. Using a search query is the ideal way to deal with that ambiguity, yet still ensure that all the required data is
  returned.
- The following example shows how a recipe can use a series of search queries to search within a data bag named
  `admins`  
  `search(:admins, '*:*')`
- Or to search the administrator named "charlie"  
  `search(:admins, 'id:charlie)`
- Or to search for an administrator with a group identifier of "ops"  
  `search(:admins, 'gid:ops')`
- Or to search administrators whose name begins with the letter `c`  
  `search(:admins, 'id:c*')`
- Data bag items that are returned by a search query can be used as if they were a hash. For example
  ```
  charlie = search(:admins, 'id:charlie').first
  puts charlie['gid'] # prints the group id of charlie
  puts charlie['shell'] # prints the shell 
  ```
- The following recipe can be used to create a user for each administrator by loading all og the items from `admins`
  data bag, looping through each admin in the data bag, and then creating a user resource so that each of those admins
  exists.
  ```
  admins = data_bag('admins')
  
  admins.each do |login|
    admin = data_bag_item('admins', login)
    home = "/home/#{login}"
    
    user login do
      uid admin['uid']
      gid admin['gid']
      shell admin['shell']
      home home
      manage_home true
    end
  end 
  ```

- And then the same recipe, modified to load administrators using a search query
  ```
  admins = []
  
  search(:admins, '*:*').each do |admin|
    login = admin['id']
    
    admins << login
    home = "/home/#{login}"
    
    user login do
      uid login['uid']
      gid login['gid']
      shell admin['shell']
      home home
      manage_home true
    end
  end
  ```

### Environments

- Values that are stored in data bags= are global to the organizations and are available to any environment.
- The tow main strategies that can be used to store shared environment data with in a data bag by using a top level key
  that corresponds to the environment or by using separate items for each environment.
- A data bag stores a top-level key for an environment might look something like this:

```
{
  "id": "some data bag item",
  "production":{
    # Hash with all your data here..
  }
  "testing":{
    # Hash with all your data here
  }
}
```

- When using a data bag in a recipe, that data can be accessed from a recipe using code similar to:
- `data_bag_item[node.chef_environemnt]['some_other_key'']`
- The other approach is to use separate items for each environment. Depending on the amount of data, it may fit nicely
  with in a single item.
- If this is the case, then creating different items for each environment may be a simple approach to providing shared
  environment values within a data bag.
- However, this approach is more time-consuming and may not scale to large environments or when the data must be stored
  in many data bags.

### Recipies

- Data bags can be accessed by a recipe in the following way
    - Loaded by name using the chef infra language. Use this approach when a only single known data bag is required.
    - Accessing through the search indexes. Use this approach when more than one data bag item is required or when the
      contents of a data bag are looped through. Search indexes will bulk-load all the data bag items, which will result
      in a lower overhead than if each data bag item were loaded by name.

#### Load with chef infra language

- The chef infra language provides access to data bags ans data bag items (including encrypted data bag items) with the
  following method.
    - `data_bag(bag)`, where `bag` us the name if the data bag
    - `data_bag_item(bag_name, item, secret)`, where a bag is the name of the data bag, item is the name of the data bag
      item. If `secret` isn't specified, a Chef infra client will look for a secret at the path specified by the
      `encrypted_data_bag_secret` setting in the client.rb file.
- The `data_bag` method returns an array with a key for each of the data bag items that are found in the data bag
    - To load the secret from a file
        - `data_bag_item('bag', 'item', IO.read('secret_file))`
    - To load a single data bag named `admins`
        - `data_bag('admins')`
    - The contents of the data bag with item naned `justin`
        - `data_bag_items('admins', 'justin')`
- If item is encrypted, `data_bag_item` will automatically decrypt it using the key specified above, or (if node is
  specified) by the `Chef::Config[:encrypted_data_bag_secret]` method, which defaults to
  `/etc/chef/encrypted_data_bag_secret`.

#### create and edit data bags

- Creating and editing the contents of a data bag or a data bag item from a recipe isn't recommended. The recommended
  method of updating a data bag or a data bag item is to use the `knife data bag` sub command.
- If action must be done from a recipe,
    - *If two operations concurrently attempt to update the contents of a data bag, the last-written attempt will be the
      operation to update the contents of the data bag. This situation can lead to data loss, so organizations should
      take steps to ensure that only one Infra Client is making updates to a data bag at a time.*
    - *Altering data bags from the node when using the open source chef infra server requires the node's API client to
      be granted admin privileges; In most cases, this isn't advisable.*
- To create data from a recipe

  ```
  users = Chef::DataBag.new
  users.name('users')
  users.create
  ```

- To create a data bag item from a recipe

  ```
  sam = {
    'id': 'sam',
    'Name': 'Sam James',
    'shell': '/bin/bash'
  }
  
  databag_item = Chef::DataBagItem.new
  databag_item.data_bag('users')
  databag_item.raw_data = sam
  databag_item.save
  ```

- To edit the contents of a data bag item from a recipe

  ```
  sam = data_bag_item('users','sam')
  sam['Name'] = 'Sam Thomas'
  sam.save
  ```