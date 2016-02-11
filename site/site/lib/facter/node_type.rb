require 'facter'

Facter.add(:node_type) do
  setcode do
    hostname = Facter.value(:fqdn)

    if hostname.start_with? "hd-"
      type = "worker"
    elsif hostname.start_with? 'dice-vm-'
      type = "vm-host"
    elsif hostname.start_with? "vm-"
      type = "vm-guest"
    elsif hostname.start_with? "dice-io-"
      type = "io-node"
    elsif hostname.start_with? "bc-"
      type = "couchdb-node"
    elsif hostname.start_with? "nn-" or hostname.start_with? "jt-"
      type = "headnode"
    elsif hostname.start_with? "lcg"
      type = "lcg-node"
    else
      type = 'unknown'
    end
    type
  end
end
