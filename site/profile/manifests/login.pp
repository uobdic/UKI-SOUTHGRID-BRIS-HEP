# Class to configure login with AD credentials
#
# Parameters:
#   @param krb5_server The KDC server
#   @param krb5_realm The realm
#   @param krb5_kpasswd The kpasswd server
class profile::login (
  String $krb5_server,
  String $krb5_realm,
  String $krb5_kpasswd,
) {
  package { ['sssd', 'sssd-krb5', 'sssd-krb5-common']:
    ensure => 'present',
  }

  sssd::domain { 'dice.priv':
    id_provider       => 'files',
    auth_provider     => 'krb5',
    chpass_provider   => 'krb5',
    access_provider   => 'simple',
    cache_credentials => true,
    enumerate         => true,
    debug_level       => 9,
  }

  sssd::provider::krb5 { 'krb5':
    krb5_server  => $krb5_server,
    krb5_realm   => $krb5_realm,
    krb5_kpasswd => $krb5_kpasswd,
  }
}
