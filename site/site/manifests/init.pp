class site {
  $node_info = hiera_hash('node_info', undef)

  if $node_info {
    file { [
      '/etc/puppetlabs/facter/',
      '/etc/puppetlabs/facter/facts.d']: ensure => directory, }

    file { '/etc/puppetlabs/facter/facts.d/node_info.yaml':
      content => template("${module_name}/node_info.erb"),
      owner   => root,
      group   => root,
      mode    => '0644',
    }
  }
}
