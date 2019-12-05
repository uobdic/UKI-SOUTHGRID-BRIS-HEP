#
class site::basic {
  $node_info = lookup('site_info::node_info', Hash, deep, {} )
  $site_info = lookup('site::site_info', Hash, deep, {} )

  if $node_info {
    file { [
      '/etc/puppetlabs/facter/',
      '/etc/puppetlabs/facter/facts.d']: ensure => directory, }

    if ($site_info and has_key($site_info, 'hepspec06_baseline')) {
      if ($node_info and has_key($node_info, 'hepspec06')) {
        $baseline                = 0 + $site_info['hepspec06_baseline']
        $node_value              = 0 + $node_info['hepspec06']
        $accounting_scale_factor = $node_value / $baseline
      }
    }

    file { '/etc/puppetlabs/facter/facts.d/node_info.yaml':
      content => template("${module_name}/node_info.erb"),
      owner   => root,
      group   => root,
      mode    => '0644',
    }

    file { '/etc/puppetlabs/facter/facts.d/site_info.yaml':
      content => template("${module_name}/site_info.erb"),
      owner   => root,
      group   => root,
      mode    => '0644',
    }
  }
}
