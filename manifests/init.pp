# this must be included in master manifest
#
#   include passgen
#
class passgen (
  $storage_path = $::passgen::params::storage_path,
) inherits ::passgen::params {
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
class passgen::vault (
  $vault_options = {},
  $vault_options_file = $::passgen::params::vault_options_file,
) inherits ::passgen::params {
  exec { 'install-vault-gem': # puppet duplicate name workaround
    command => 'gem install vault',
    unless  => 'gem list | grep vault',
  }
  file { $vault_options_file:
    ensure    => present,
    content   => inline_template('<%= @vault_options.to_yaml %>'),
    show_diff => false,
  }
}
