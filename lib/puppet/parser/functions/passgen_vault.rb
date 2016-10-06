require 'yaml'

module Puppet::Parser::Functions
  newfunction(:passgen_vault, :type => :rvalue) do |args|
    require 'chronic_duration'
    require 'vault'
    ChronicDuration.raise_exceptions = true

    name = args[0]

    expire = nil
    if args[1]
        expire = ChronicDuration.parse(args[1])
    end

    if args[2]
        gen_value = args[2]
    else
        gen_value = `pwgen -s -1 14`.chomp
    end

    options = YAML::load_file lookupvar('passgen::vault::vault_options_file')
    if not options.is_a?(Hash) then raise "Config options is not a hash!" end
    options.each do |key, value|
      Vault.client.instance_variable_set(:"@#{key}", value)
    end

    store = {}
    Vault.with_retries(Vault::HTTPConnectionError) do
          store = Vault.logical.read("secret/#{name}")
    end
    pass = store['value']
    stored_expire = store['expire']
    expire_duration = store['expire_duration']
    if not pass or (expire and stored_expire ? Time.now.to_i > stored_expire : false) or expire_duration != args[1]
      Vault.with_retries(Vault::HTTPConnectionError) do
        Vault.logical.write("secret/#{name}",
                             value: gen_value,
                             expire: expire ? Time.now.to_i + expire : expire,
                             expire_duration: args[1])
      end
    end

    pass
  end
end
