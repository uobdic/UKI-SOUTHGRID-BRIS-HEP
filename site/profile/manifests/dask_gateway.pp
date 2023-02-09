# Sets up a dask gateway server
# https://gateway.dask.org/
class profile::dask_gateway {
  firewall { '940 allow dask scheduler':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '8786',
    action => 'accept',
  }
}
