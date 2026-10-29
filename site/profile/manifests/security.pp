# class for public mitigations for security vulnerabilities
class profile::security {
  contain profile::security::dirtyfrag
  contain profile::security::network_namespaces
}
