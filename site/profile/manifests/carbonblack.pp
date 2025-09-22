# Configure Carbon Black cloud agent
#
class profile::carbonblack {
  # Lookup data
  # ====================================================================

  $enable_carbonblack = lookup('profile::carbonblack::enable', { 'type' => Boolean, 'default_value' => true, })
  $carbonblack_baseurl = lookup('profile::carbonblack::baseurl', { 'type' => Stdlib::HTTPSUrl, })

  # Calculate variables
  # ====================================================================

  $supported_distro = "${facts['os']['family']}-${facts['os']['release']['major']}" ? {
    default                         => false,
    /^RedHat-(7|8|9)$/              => true,
    /^Debian-(16|18|20|22|24)\.04$/ => true,  # Ubuntu LTS releases really but Debian family..
  }

  if $supported_distro {
    $rpm_or_deb = $facts['os']['family'] ? {
      default  => 'rpm',
      'Debian' => 'deb',
    }

    # Actions
    # ==================================================================

    # Un-disguise Rocky now that CB XDR supports it
    if "${facts['os']['name']}-${facts['os']['release']['major']}" == 'Rocky-8' {
      file_line { 'undisguise /etc/os-release on Rocky hosts':
        path  => '/etc/os-release',
        match => '^ID="rhel"',
        line  => "ID=\"rocky\"",
      }
    }

    # If CB EDR is installed then remove both it and XDR via this script:
    file { '/usr/local/bin/remove-edr-xdr.sh':
      content => epp('profile/carbonblack/remove-edr-xdr.sh',
        {
          'rpm_or_deb' => $rpm_or_deb,
        }
      ),
      group   => 'root',
      mode    => '0755',
      owner   => 'root',
    }
    exec { 'remove-edr-xdr.sh':
      require => File['/usr/local/bin/remove-edr-xdr.sh'],
      command => '/usr/local/bin/remove-edr-xdr.sh',
      onlyif  => '/usr/bin/test -d /var/opt/carbonblack/install',
      notify  => Class['cbagent'],  # Ensure XDR put back on if requested
    }

    # Include the CB XDR `cbagent' module.
    # (Note that the class resource style of inclusion is apparently
    # not supported, but we're going to use it anyway to allow setting
    # the dependencies when required!)
    class { 'cbagent' :
      ensure  => bool2str($enable_carbonblack, 'running', 'absent'),
      # Pull CB script and archive from server
      # (This checksums the files to ensure they are valid)
      baseurl => $carbonblack_baseurl,
    }

    if $facts['os']['family'] == 'Debian' {
      # Workaround for `systemd daemon-reload` not being called on Ubuntu on upgrade from 7.0.1
      include systemd::systemctl::daemon_reload
      Class['cbagent'] ~> Class['systemd::systemctl::daemon_reload']
    }
  }
}
