# Puppet password generator

Ever been in situation when you wanted to generate a password with puppet,
but didn't want it to be regenerated at each puppet run?

Exec-based solutions work, but they are not efficient nor flexible. Here is where passgen comes.

# How to use

First of all, you need to include passgen on your puppet master. It's worth to note that all
generated password will be saved on master.

```puppet
include passgen
```
or
```puppet
class { 'passgen':
  storage_path => '/tmp/generated_passwords',
}
```

The storage path must already be created by puppet or manually.

Now you can use it on your nodes, for example:
```puppet
rabbitmq_user { 'sa':
  admin    => true,
  password => passgen('rabbitmq_sa'),
```
Or create a password with expiration:
```puppet
rabbitmq_user { 'sa':
  admin    => true,
  password => passgen('rabbitmq_sa', "30 days"),
```

You can even export resource in usual puppet way and use it on another node.
