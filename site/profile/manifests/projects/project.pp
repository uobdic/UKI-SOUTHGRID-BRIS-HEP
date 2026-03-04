# profile::projects::project
#
# Create and manage a single project directory within the
# `/dice/projects` hierarchy.
#
# Projects represent research work areas owned by a sponsor
# and optionally shared with collaborators.
#
# Each project directory includes:
#
# - Sponsor ownership.
# - CephFS storage quota.
# - Read access via experiment or explicit group.
# - Optional write access for specific users via ACL.
# - A generated README.md documenting the configuration.
#
# Access model:
#
# - Sponsor owns the directory.
# - Experiment members (or configured read_group) receive
#   read/traverse permissions.
# - Writers receive read/write/execute permissions via ACL.
# - Default ACLs ensure permissions propagate to newly
#   created files and directories.
#
# @param root
#   Absolute path of the projects root directory.
#
# @param defaults
#   Hash of global defaults inherited from `profile::projects`.
#
#   Used for:
#
#   - minimum quota enforcement
#   - default permission mode
#   - README filename
#
# @param sponsor
#   Unix username representing the academic sponsor of the project.
#
#   This user becomes the filesystem owner of the project directory.
#
# @param quota_gib
#   Storage quota for the project in GiB.
#
#   This value is converted to bytes and applied as the CephFS
#   extended attribute `ceph.quota.max_bytes`.
#
#   If the value is below `quota_gib_min` defined in `defaults`,
#   the minimum quota will be applied instead.
#
# @param writers
#   Array of Unix usernames granted write access to the project.
#
#   Write access is implemented via POSIX ACL entries and includes
#   default ACLs so that new files inherit permissions automatically.
#
# @param description
#   Free-text description of the project purpose.
#
#   Included in the generated README.md file.
#
# @param experiments
#   Hash describing experiment umbrella configuration.
#
#   This is used to determine inherited read access based on the
#   first path component of the project name.
#
#   Example:
#
#     CMS/ttbar → experiment "CMS"
#
# @param read_group
#   Optional explicit Unix group granted read access.
#
#   If not defined, the experiment group (derived from the path)
#   will be used if available.
#
# @param extra_read_groups
#   Array of additional Unix groups granted read/traverse access
#   to the project directory via ACL.
#
define profile::projects::project (
  String $root,
  Hash $defaults,
  String $sponsor,
  Integer $quota_gib,
  Array[String] $writers,
  Optional[String] $description = '',
  Hash $experiments,
  Optional[String] $read_group = undef,
  Array[String] $extra_read_groups = [],
) {
  $path = "${root}/${title}"

  $segments = split($title, '/')
  $maybe_experiment = $segments[0]

  $experiment_group = $experiments[$maybe_experiment] ? {
    undef   => undef,
    default => $experiments[$maybe_experiment]['group'],
  }

  $effective_read_group = $read_group ? {
    undef   => $experiment_group,
    default => $read_group,
  }

  $min_gib     = $defaults.get('quota_gib_min', 10)
  $quota_gib_2 = $quota_gib < $min_gib ? { true => $min_gib, false => $quota_gib }
  $quota_bytes = $quota_gib_2 * 1024 * 1024 * 1024

  $parent = dirname($path)
  file { $parent:
    ensure  => directory,
    owner   => 'root',
    group   => $effective_read_group ? { undef => 'root', default => $effective_read_group },
    mode    => $defaults.get('mode_root', '2750'),
    require => File[$root],
  }

  file { $path:
    ensure  => directory,
    owner   => $sponsor,
    group   => $effective_read_group ? { undef => 'root', default => $effective_read_group },
    mode    => $defaults.get('mode_root', '2750'),
    require => File[$parent],
  }

  exec { "set_cephfs_quota_${title}":
    command => "/usr/bin/setfattr -n ceph.quota.max_bytes -v ${quota_bytes} ${path}",
    unless  => "/usr/bin/getfattr -n ceph.quota.max_bytes ${path} 2>/dev/null | /bin/grep -q ${quota_bytes}",
    require => File[$path],
  }

  # Build ACL permission list
  $perm = [
    # baseline
    'user::rwx',
    'group::r-x',
    'mask::rwx',
    'other::---',
  ]

  if $effective_read_group {
    $perm += ["group:${effective_read_group}:r-x"]
  }

  $extra_read_groups.each |String $g| {
    $perm += ["group:${g}:r-x"]
  }

  $writers.each |String $u| {
    $perm += ["user:${u}:rwx"]
  }

  # defaults (inheritance)
  $perm += [
    'default:user::rwx',
    'default:group::r-x',
    'default:mask::rwx',
    'default:other::---',
  ]

  if $effective_read_group {
    $perm += ["default:group:${effective_read_group}:r-x"]
  }

  $extra_read_groups.each |String $g| {
    $perm += ["default:group:${g}:r-x"]
  }

  $writers.each |String $u| {
    $perm += ["default:user:${u}:rwx"]
  }

  posix_acl { $path:
    action     => 'exact',
    provider   => posixacl,
    recursive  => false,
    permission => $perm,
    require    => File[$path],
  }

  $readme = @("README")
    # ${title}

**Purpose**
${description}

**Sponsor (owner)**
- ${sponsor}

**Quota**
- ${quota_gib_2} GiB (${quota_bytes} bytes)

**Read access**
- Primary read group: ${effective_read_group ? { undef => '(none)', default => $effective_read_group }}
- Extra read groups: ${extra_read_groups.empty ? { true => '(none)', false => join($extra_read_groups, ', ') }}

**Write access (ACL)**
- ${writers.empty ? { true => '(none)', false => join($writers, ', ') }}

**Notes**
- ACLs are managed with Puppet using posix_acl (exact mode) on the project root.
- Default ACLs are set so new children inherit access settings.
  | README

  file { "${path}/${defaults.get('readme_filename', 'README.md')}":
    ensure  => file,
    owner   => $sponsor,
    group   => $effective_read_group ? { undef => 'root', default => $effective_read_group },
    mode    => '0644',
    content => $readme,
    require => File[$path],
  }
}
