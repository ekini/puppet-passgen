require 'pstore'

module Puppet::Parser::Functions
  newfunction(:passgen, :type => :rvalue) do |args|
    require 'chronic_duration'
    ChronicDuration.raise_exceptions = true

    filename = args[0]

    expire = nil
    if args[1]
        expire = ChronicDuration.parse(args[1])
    end

    if args[2]
        gen_value = args[2]
    else
        gen_value = `pwgen -s -1 14`.chomp
    end

    store = PStore.new(File.join(lookupvar('passgen::params::storage_path'), filename))
    pass = store.transaction { store['value'] }
    stored_expire = store.transaction { store['expire'] }
    expire_duration = store.transaction { store['expire_duration'] }
    if not pass or (expire and stored_expire ? Time.now.to_i > stored_expire : false) or expire_duration != args[1]
      pass = store.transaction do
          store['value'] = gen_value
      end
      store.transaction do
          store['expire'] = expire ? Time.now.to_i + expire : expire
          store['expire_duration'] = args[1]
      end
    end

    pass
  end
end
