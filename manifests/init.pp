# this must be included in master manifest
#
#   include passgen
#
class passgen inherits passgen::params {
  package { 'chronic_duration':
    ensure   => present,
    provider => gem,
  }
  file { $::passgen::params::storage_path:
    ensure  => directory,
    recurse => true,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0700',
  }

}
