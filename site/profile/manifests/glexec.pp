class profile::glexec{

  $site_name    = $::site_info['gocdb_name']
  $default_se   = $::site_info['storage_element']
  $argus_server = $::site_info['argus_server']

  include ::glexecwn
}
