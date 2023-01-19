# profile for prometheus monitoring
class profile::monitored::prometheus {
  include prometheus::node_exporter
}
