# just a simpele profile to summarise all monitoring
class profile::monitored {
  # ganglia
  include ::profile::monitored::ganglia
  # smartd
  include ::profile::monitored::smartd

  # central log
  include ::profile::monitored::central_log

  # psacct
  include ::profile::monitored::psacct
}
