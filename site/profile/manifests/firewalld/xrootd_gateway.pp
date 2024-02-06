# Configure port 1094 for XRootD Gateway
class profile::firewalld::xrootd_gateway {
  firewalld::custom_service { 'xrootd_gateway':
    short       => 'XRootD Gateway',
    description => 'Allow access to XRootD Gateway on port 1094',
    port        => '1094',
    protocol    => 'tcp',
    zone        => 'public',
    ipv4        => true,
    ipv6        => true,
  }
}
