# profile::projects::experiment
#
# Create and manage an experiment "umbrella" directory under the
# project root (for example `/dice/projects/CMS`).
#
# Umbrella directories provide:
#
# - A stable namespace for experiment projects.
# - Default read/traverse access for the experiment group.
# - Default ACL inheritance so subprojects automatically allow
#   experiment members to read the directory structure.
#
# The directory is created with the setgid bit enabled so that
# newly created subdirectories inherit the experiment group.
#
# @param root
#   Absolute path to the projects root directory.
#
# @param group
#   Unix group representing the experiment membership.
#
#   Members of this group receive read and traverse permissions
#   on the experiment directory and all inherited subdirectories.
#
# @param description
#   Optional free-text description of the experiment area.
#   When provided, a README.md file is generated containing
#   this description.
#
# @param mode
#   Directory permission mode.
#
#   Default: `2750`
#
#   Meaning:
#
#   - Owner: read/write/execute
#   - Group: read/execute
#   - Other: no access
#   - setgid bit ensures group inheritance for subdirectories.
#
define profile::projects::experiment (
  String $root,
  String $group,
  Optional[String] $description = undef,
  String $mode = '2750',
) {
  $path = "${root}/${title}"
  $token = regsubst($title, '[^A-Za-z0-9._-]', '_', 'G')
  $aclfile = "/etc/dice/acl/projects/experiment_${token}.acl"

  file { $path:
    ensure  => directory,
    owner   => 'root',
    group   => $group,
    mode    => $mode,
    require => File[$root],
  }

  file { $aclfile:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('profile/projects/acl.epp', {
        'path'              => $path,
        'group'             => $group,
        'extra_read_groups' => [],
        'writers'           => [],
        'allow_writers'     => false,   # umbrellas: read-only
    }),
    require => File['/etc/dice/acl/projects'],
  }

  exec { "apply_acl_${aclfile}":
    command => "/usr/bin/setfacl --set-file ${aclfile} ${path}",
    unless  => "/usr/bin/getfacl -c --absolute-names --no-effective ${path} | /usr/bin/diff -u - ${aclfile} >/dev/null",
    path    => ['/usr/bin','/bin'],
    require => [File[$path], File[$aclfile]],
  }

  if $description != '' {
    file { "${path}/README.md":
      ensure  => file,
      owner   => 'root',
      group   => $group,
      mode    => '0644',
      content => "# ${title}\n\n${description}\n",
      require => [File[$path], File[$aclfile]],
    }
  }
}
