# Fact: has_enabled_epel_repo
#
# Purpose: Report if the EPEL repo is enabled
#
Facter.add(:has_enabled_epel_repo) do
  setcode do
    begin
      Facter::Util::Resolution.exec("cat /etc/yum.repos.d/epel*.repo | grep enabled=1 | wc -l")
    rescue Exception
      Facter.debug('epel repository not found')
    end
  end
end
