# just a simpele profile to summarise all monitoring
class profile::monitored {
  $add_prometheus = lookup('profile::monitored::add_prometheus', Boolean, undef, true)
  if $add_prometheus {
    # some nodes already have prometheus due to their services
    include profile::monitored::prometheus
  }

  # smartd
  include profile::monitored::smartd

  # central log
  include profile::monitored::central_log

  # psacct
  include profile::monitored::psacct
}
