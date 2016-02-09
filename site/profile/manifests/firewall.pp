# Clears rules and sets up pre and post classes
class profile::firewall {
    resources { '::firewall':
        purge => true
    }

    Firewall {
        before  => Class['profile::firewall::post'],
        require => Class['profile::firewall::pre'],
    }

    class { ['profile::firewall::pre', 'profile::firewall::post']: }

#    $firewall_rules = hiera_hash('firewall_rules')
#    create_resources('firewall', $firewall_rules)
}
