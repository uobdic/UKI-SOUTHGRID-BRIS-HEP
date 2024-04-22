# class for configuring HTCondor
# @param role: The role of the node, either 'execute', 'manager', or 'submit'
class profile::htcondor (
  String $role = 'execute',
) {
  if $role == 'execute' {
    include profile::htcondor::execute
  } elsif $role == 'central-manager' {
    include profile::htcondor::central_manager
  } elsif $role == 'submit' {
    include profile::htcondor::submit
  } else {
    fail("Invalid role ${role}")
  }
}
