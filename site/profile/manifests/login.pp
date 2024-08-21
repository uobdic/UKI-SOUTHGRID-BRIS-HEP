# Class to configure login with AD credentials
class profile::login {
  package { ['pam_krb5', 'krb5-workstation', 'sssd-krb5']:
    ensure => 'present',
  }
}
