# Clears rules and sets up pre and post classes
class profile::firewall {
    resources { '::firewall':
        purge => true
    }

    Firewall {
        before  => Class['profiles::firewall::post'],
        require => Class['profiles::firewall::pre'],
    }

    class { ['profiles::firewall::pre', 'profiles::firewall::post']: }

#    $firewall_rules = hiera_hash('firewall_rules')
#    create_resources('firewall', $firewall_rules)
}
