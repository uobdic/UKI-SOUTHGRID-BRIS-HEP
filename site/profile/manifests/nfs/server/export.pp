# A single NFS export
#
# @param clients          Array of client addresses or hostnames
# @param options          Array of export options
# @param automount        Boolean to enable automounting (default: false)
# @param clientpath       Optional path for the client mount point
# @param homedirs_context Boolean to enable context for home directories (default: false)
# @param path             The export path on the NFS server
#
define profile::nfs::server::export (
  Array[String]        $clients,
  Array[String]        $options,
  Boolean              $automount        = false,
  Stdlib::Absolutepath $clientpath       = $name,
  Boolean              $homedirs_context = false,
  Stdlib::Absolutepath $path             = $name,
) {
  # Massage data formats
  # ====================================================================

  $options_string = $options.join(',')
  $clients_string = $clients.reduce('') |$memo, $client| {
    "${memo}${client}(${options_string}) "
  }

  # Configure the export
  # ====================================================================

  nfs::server::export { $path:
    ensure  => 'mounted',
    clients => $clients_string,
    atboot  => true,
    mount   => $clientpath,
  }

  if $homedirs_context and $facts['os']['selinux']['enabled'] {
    selinux::fcontext { $path:
      seltype  => 'home_root_t',
      pathspec => $path,
    }
  }
}
