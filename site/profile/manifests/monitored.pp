# @summary just a simpele profile to summarise all monitoring
#
# @param use_prometheus [Boolean] Whether to use Prometheus for monitoring.
# @param use_smartd [Boolean] Whether to enable SMARTd
# @param use_central_logging [Boolean] Whether to enable central logging
# @param use_process_accounting [Boolean] Whether to use psacct
#
class profile::monitored (
  Boolean $use_prometheus = true,
  Boolean $use_smartd = true,
  Boolean $use_central_logging = true,
  Boolean $use_process_accounting = true,
) {
  notify {
    "Settings for monitoring: prometheus=${use_prometheus}, smartd=${use_smartd},\
     central_logging=${use_central_logging}, psacct=${use_process_accounting}":
  }
  if $use_prometheus {
    # some nodes already have prometheus due to their services
    include profile::monitored::prometheus
  }

  # smartd
  if $use_smartd {
    include profile::monitored::smartd
  }

  # central log
  if $use_central_logging {
    include profile::monitored::central_log
  }

  # psacct
  if $use_process_accounting {
    include profile::monitored::psacct
  }
}
