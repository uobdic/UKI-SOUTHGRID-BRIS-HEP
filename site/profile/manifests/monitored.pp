# just a simpele profile to summarise all monitoring
class profile::monitored {
  $next_gen_monitoring = lookup('profile::monitored::next_gen_monitoring', Boolean, 'first', false)

  # ganglia
  include ::profile::monitored::ganglia

  if $next_gen_monitoring {
    # next-gen monitoring
    include ::profile::monitored::prometheus
  }

  # smartd
  include ::profile::monitored::smartd

  # central log
  include ::profile::monitored::central_log

  # psacct
  include ::profile::monitored::psacct
}
