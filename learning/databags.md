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

TODO: Use data bags