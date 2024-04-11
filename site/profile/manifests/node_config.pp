# node config
class node_config {
  include stdlib

  $node_info = lookup('site::node_info', Hash, deep, {})
  $site_info = lookup('site::site_info', Hash, deep, {})
  # TODO: all DICE parts will be in a separate puppet module
  $dice = lookup('dice', Hash, deep, {})
  $dice_computing_grid = lookup('dice::computing_grid', Hash, deep, {})
  $dice_storage = lookup('dice::storage', Hash, deep, {})
  $dice_glossary = lookup('dice::glossary', Hash, deep, {})

  # notify {'site::basic':
  #   message => "Applying site_info (${site_info}) and node_info (${node_info})"
  # }

  if $node_info or $site_info {
    file { [
        '/etc/puppetlabs/facter/',
    '/etc/puppetlabs/facter/facts.d']: ensure => directory, }

    if ($site_info and $site_info['hepspec06_baseline']) {
      if ($node_info and $node_info['hepspec06']) {
        $baseline                = 0 + $site_info['hepspec06_baseline']
        $node_value              = 0 + $node_info['hepspec06']
        $accounting_scale_factor = $node_value / $baseline
      }
    }
  }

  if $node_info {
    file { '/etc/puppetlabs/facter/facts.d/node_info.yaml':
      content => template("${module_name}/node_info.erb"),
      owner   => root,
      group   => root,
      mode    => '0644',
    }
  }

  if $site_info {
    file { '/etc/puppetlabs/facter/facts.d/site_info.yaml':
      content => template("${module_name}/site_info.erb"),
      owner   => root,
      group   => root,
      mode    => '0644',
    }
  }

  if $dice {
    file { '/etc/dice':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    file { '/etc/dice/config.yaml':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/dice_config.yaml.erb"),
      require => File['/etc/dice'],
    }
  }
}
