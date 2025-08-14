# Configure NFS server
#
class profile::nfs::server {
  # Hiera data
  # ====================================================================

  $default_options = lookup('profile::nfs::server::default_options', { default_value => [], merge => 'deep', value_type => Array, })
  $extra_packages  = lookup('profile::nfs::server::extra_packages', { default_value => [], merge => 'deep', value_type => Array, })
  $extra_services  = lookup('profile::nfs::server::extra_services', { default_value => [], merge => 'deep', value_type => Array, })
  $idmap_domain    = lookup('profile::nfs::idmap_domain', { default_value => 'nfs', value_type => String, })

  $exports        = lookup('profile::nfs::server::exports', {
    default_value => [],
    merge         => 'deep',
    value_type    => Hash[String, Struct[{
      clients          => Array[String],
      options          => Optional[Array[String]],
      automount        => Optional[Boolean],
      clientpath       => Optional[Stdlib::Absolutepath],
      homedirs_context => Optional[Boolean],
    }]],
  })

  # Prepare the system
  # ====================================================================

  stdlib::ensure_packages($extra_packages)

  class { 'nfs':
    client_enabled         => true,  # All NFS servers should also have the client enabled
    server_enabled         => true,
    nfs_v4                 => true,
    nfsv4_bindmount_enable => false,  # We don't use the bind mounts
    nfs_v4_idmap_domain    => $idmap_domain,
  }

  service { $extra_services:
    ensure  => running,
    require => Class['nfs'],
    enable  => true,
  }

  # Client mounts
  # ====================================================================

  include profile::nfs::client::mounts

  # Exports
  # ====================================================================

  $exports.each |$path, $parameters| {
    $user_options = pick_default($parameters['options'], [])

    $options = union($default_options, $user_options)

    profile::nfs::server::export { $path:
      clients          => $parameters['clients'],
      options          => $options,
      automount        => pick($parameters['automount'], false),
      clientpath       => $parameters['clientpath'],
      homedirs_context => pick($parameters['homedirs_context'], false),
    }
  }

  # Firewall
  # ====================================================================

  $all_clients = $exports.values.map |$export| { $export['clients'] }.flatten.unique

  $all_clients.each |$client| {
    $rule_defaults = {
      source  => $client,
      zone    => 'public',
      action  => 'accept',
      require => Class['nfs'],
    }

    $services = [
      # 'lockd',    # Not configugured on existing server
      'mountd',    # tcp|udp 20048
      'nfs',       # tcp 2049
      'rquotad',   # tcp|udp 875
      'rpc-bind',  # tcp|udp 111
      # 'statd',    # Not configugured on existing server
    ]
    $services.each |$service| {
      firewalld_rich_rule { "Accept ${service} from ${client}":
        service => $service,
        *       => $rule_defaults,
      }
    }
  }
}
