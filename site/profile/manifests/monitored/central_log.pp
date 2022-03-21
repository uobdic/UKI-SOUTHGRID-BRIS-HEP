# manages the central logging behaviour of a machine (using rsyslog)
class profile::monitored::central_log {
  $central_log = lookup('profile::monitored::central_log', Array, 'first', ['*.* @10.129.5.3:514'])
  $it_services_log = lookup('profile::monitored::it_services_log', Array, 'first', [])
  $is_central_log = member($central_log, $::fqdn) or member($central_log,
  $::ipaddress)

  unless $is_central_log {
    include rsyslog::config
  }
}
