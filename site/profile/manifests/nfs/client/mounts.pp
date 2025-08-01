# Configure the mounts for an NFS client
#
class profile::nfs::client::mounts {
  # Hiera data
  # ====================================================================

  $default_options = lookup('profile::nfs::client::default_options', { default_value => [], merge_type => 'deep', value_type => Array, })

  $mounts = lookup('profile::nfs::client::mounts', {
    default_value => {},
    merge_type => 'deep',
    value_type => Hash[Stdlib::Absolutepath, Struct[{
      server   => String,
      share    => String,
      ensure   => Optional[Enum['absent', 'mounted', 'present', 'unmounted']],
      options  => Optional[Array[String]],
      readonly => Optional[Boolean],
    }]]
  })

  # Mounts
  # ====================================================================

  $mounts.each |$path, $parameters| {
    # Make sure the user options don't include 'ro' or 'rw' as these are handled separately
    $user_options = difference($parameters['options'], ['ro','rw'])

    # Merge default options, user options, and read-write handling
    $options = union(
      $parameters['readonly'] ? { false => ['rw'], default => ['ro'] },
      $default_options,
      $user_options,
    ).join(',')

    nfs::client::mount { $path:
      ensure      => pick($parameters['ensure'], 'mounted'),
      server      => $parameters['server'],
      share       => $parameters['share'],
      mount       => $path,
      options_nfs => $options,
    }
  }
}
