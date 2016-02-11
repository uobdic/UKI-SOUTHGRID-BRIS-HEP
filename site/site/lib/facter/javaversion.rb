# Fact: javaversion
#
# Purpose: Report the version of java
#
Facter.add(:javaversion) do
  setcode do
    begin
      Facter::Util::Resolution.exec("java -version 2>&1").split("\n")[0].split('"')[1] 
    rescue Exception
      Facter.debug('java not available')
    end
  end
end
