# some extras for the puppet server configuration
class profile::puppetserver {
  file { '/etc/puppetlabs/code/hiera.yaml':
    ensure => 'link',
    target => '/etc/puppetlabs/code/environments/production/hiera.yaml',
  }
}
