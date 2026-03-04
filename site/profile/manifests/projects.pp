# profile::projects
#
# Manage the DICE CephFS project storage hierarchy under /dice/projects.
#
# Responsibilities:
# - Create the global project root directory.
# - Create experiment "umbrella" directories (e.g. /dice/projects/CMS).
# - Create individual project directories from Hiera definitions.
# - Configure CephFS quotas on project directories.
# - Configure access permissions using POSIX ACLs.
# - Generate README.md documentation files describing each project.
#
# Projects are defined in Hiera and consist of:
# - a sponsor (Unix owner)
# - a quota (defined in GiB)
# - optional read groups
# - optional write users
#
# Umbrella experiment directories provide inherited read access to
# all experiment members and ensure consistent group permissions.
#
# @param root
#   Absolute path of the projects root directory.
#   Typically `/dice/projects`.
#
# @param defaults
#   Hash of default configuration values applied to projects.
#
#   Supported keys:
#
#   - `mode_root`
#       Default permission mode applied to project directories.
#       Recommended value: `2750` (setgid + group read).
#
#   - `quota_gib_default`
#       Default quota in GiB if not specified in the project definition.
#
#   - `quota_gib_min`
#       Minimum allowed quota in GiB. Any project quota below this value
#       will be raised to this minimum.
#
#   - `readme_filename`
#       Name of the README file generated in each project directory.
#
# @param experiments
#   Hash describing experiment umbrella directories.
#
#   Each key represents the directory name under the project root
#   (for example `CMS` → `/dice/projects/CMS`).
#
#   Values must include:
#
#   - `group`
#       Unix group granted read/traverse access to the experiment area.
#
#   Optional fields:
#
#   - `description`
#       Human-readable description written into the experiment README.
#
#   - `mode`
#       Directory permission mode.
#
# @param projects
#   Hash describing individual projects.
#
#   Keys represent relative paths under the project root.
#
#   Example:
#
#     CMS/ttbar
#
#   Required fields:
#
#   - `sponsor`
#       Unix username who becomes the directory owner.
#
#   Optional fields:
#
#   - `quota_gib`
#       Project quota in GiB.
#
#   - `writers`
#       Array of users granted write access via ACL.
#
#   - `read_group`
#       Explicit Unix group granted read access. If omitted, the group
#       of the experiment umbrella (derived from the path prefix)
#       will be used if available.
#
#   - `extra_read_groups`
#       Additional groups granted read/traverse access.
#
#   - `description`
#       Text describing the purpose of the project. Included in README.md.
#
class profile::projects (
  String $root        = lookup('profile::projects::root', String, 'first', '/dice/projects'),
  Hash   $defaults    = lookup('profile::projects::defaults', Hash, 'deep', {}),
  Hash   $experiments = lookup('profile::projects::experiments', Hash, 'deep', {}),
  Hash   $projects    = lookup('profile::projects::projects', Hash, 'deep', {}),
) {
  file { $root:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  ensure_resource('file', '/etc/dice', { ensure=> directory })
  file { '/etc/dice/acl':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/dice'],
  }

  file { '/etc/dice/acl/projects':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/dice/acl'],
  }

  $experiments.each |String $name, Hash $cfg| {
    profile::projects::experiment { $name:
      root        => $root,
      group       => $cfg['group'],
      description => $cfg.get('description', ''),
      mode        => $cfg.get('mode', $defaults.get('mode_root', '2750')),
    }
  }

  $projects.each |String $relpath, Hash $cfg| {
    profile::projects::project { $relpath:
      root              => $root,
      defaults          => $defaults,
      sponsor           => $cfg['sponsor'],
      quota_gib         => $cfg.get('quota_gib', $defaults.get('quota_gib_default', 0)),
      writers           => $cfg.get('writers', []),
      description       => $cfg.get('description', ''),
      experiments       => $experiments,
      read_group        => $cfg.get('read_group', undef),
      extra_read_groups => $cfg.get('extra_read_groups', []),
    }
  }
}
