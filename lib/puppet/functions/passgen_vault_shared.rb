# This is an autogenerated function, ported from the original legacy version.
# It /should work/ as is, but will not have all the benefits of the modern
# function API. You should see the function docs to learn how to add function
# signatures for type safety and to document this function using puppet-strings.
#
# https://puppet.com/docs/puppet/latest/custom_functions_ruby.html
#
# ---- original file header ----
require 'yaml'
# passgen_vault_shared($name, $expire, $pwd, $facts, $shared)
# ---- original file header ----
#
# @summary
#   Summarise what the function does here
#
Puppet::Functions.create_function(:'passgen_vault_shared') do
  # @param args
  #   The original array of arguments. Port this to individually managed params
  #   to get the full benefit of the modern function API.
  #
  # @return [Data type]
  #   Describe what the function returns here
  #
  dispatch :default_impl do
    # Call the method named 'default_impl' when this is matched
    # Port this to match individual params for better type safety
    repeated_param 'Any', :args
  end


  def default_impl(*args)
    
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
    shared = []
    if args[4]
      shared = args[4].map do |rule|
        rule.map do |key, value|
          "#{key}_#{value}"
        end.sort.join('/')
      end
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
      secret = Vault.logical.read("secret/shared/#{facts}/#{name}")
      if secret
        if secret.data
          store = secret.data
        end
      end
    end
    pass = store[:value]
    stored_expire = store[:expire]
    expire_duration = store[:expire_duration]
    owner = store[:owner]
    oldshared = store[:shared]
    if not pass or (expire and stored_expire ? Time.now.to_i > stored_expire : false) or expire_duration != args[1]
      if not pass or ( pass and owner == facts )
        Vault.with_retries(Vault::HTTPConnectionError) do
          Vault.logical.write("secret/shared/#{facts}/#{name}",
                              value: gen_value,
                                expire: expire ? Time.now.to_i + expire : expire,
                                expire_duration: args[1],
                                owner: facts,
                                shared: shared,
                                ttl: expire)
          pass = gen_value
        end
      end
    end
    # for each other owner(s) if expired or not shared
    if oldshared != shared or not pass or (expire and stored_expire ? Time.now.to_i > stored_expire : false) or expire_duration != args[1]
      shared.each do |path|
        Vault.with_retries(Vault::HTTPConnectionError) do
          Vault.logical.write("secret/shared/#{path}/#{name}",
                              value: pass,
                                expire: expire ? Time.now.to_i + expire : expire,
                                expire_duration: args[1],
                                owner: facts,
                                shared: shared,
                                ttl: expire)
        end
      end
    end
    pass
  
  end
end