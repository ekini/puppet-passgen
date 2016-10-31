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

    if args[2] and args[2] != ''
        gen_value = args[2]
    else
        gen_value = `pwgen -s -1 14`.chomp
    end

    facts = "__common"
    if args[3]
        facts_array = args[3].sort.map do |fact|
            value = lookupvar(fact)
            "#{fact}_#{value}"
        end
        facts = facts_array.join("/")
    end

    options_file = lookupvar('passgen::params::vault_options_file')
    if options_file.nil? then raise Puppet::ParseError, "options file path is empty, probably forgot to include puppet::params" end

    options = YAML::load_file options_file
    if not options.is_a?(Hash) then raise "Config options is not a hash!" end
    options.each do |key, value|
      Vault.client.instance_variable_set(:"@#{key}", value)
    end

    store = {}
    Vault.with_retries(Vault::HTTPConnectionError) do
      # with probability 10% self-renew token
      if Random.rand <= 0.1
        begin
          Vault.client.auth_token.renew_self
        rescue
        end
      end
      secret = Vault.logical.read("secret/#{facts}/#{name}")
      if secret
          if secret.data
            store = secret.data
          end
      end
    end
    pass = store[:value]
    stored_expire = store[:expire]
    expire_duration = store[:expire_duration]
    if not pass or (expire and stored_expire ? Time.now.to_i > stored_expire : false) or expire_duration != args[1]
      Vault.with_retries(Vault::HTTPConnectionError) do
        Vault.logical.write("secret/#{facts}/#{name}",
                             value: gen_value,
                             expire: expire ? Time.now.to_i + expire : expire,
                             expire_duration: args[1],
                             ttl: expire)
        pass = gen_value
      end
    end

    pass
  end
end
