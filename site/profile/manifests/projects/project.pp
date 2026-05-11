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
  Hash $experiments,
  Optional[String] $description = undef,
  Optional[String] $read_group = undef,
  Array[String] $extra_read_groups = [],
) {
  $path = "${root}/${title}"

  $segments = split($title, '/')

  # Only treat the first path component as an experiment if this is
  # actually an experiment/project-style path, e.g. CMS/ttbar.
  #
  # Top-level projects are therefore not assumed to belong to an experiment.
  $maybe_experiment = $segments.length > 1 ? {
    true    => $segments[0],
    default => undef,
  }

  $experiment_group = $maybe_experiment ? {
    undef   => undef,
    default => $experiments[$maybe_experiment] ? {
      undef   => undef,
      default => $experiments[$maybe_experiment]['group'],
    },
  }

  $experiment_root = $experiment_group ? {
    undef   => undef,
    default => "${root}/${maybe_experiment}",
  }

  $effective_read_group = $read_group ? {
    undef   => $experiment_group,
    default => $read_group,
  }

  $project_group = $effective_read_group ? {
    undef   => 'root',
    default => $effective_read_group,
  }

  $min_gib     = $defaults.get('quota_gib_min', 10)
  $quota_gib_2 = $quota_gib < $min_gib ? { true => $min_gib, false => $quota_gib }
  $quota_bytes = $quota_gib_2 * 1024 * 1024 * 1024

  $parent = dirname($path)

  # Only ensure the parent directory if it's not the experiment umbrella itself.
  # Experiment umbrellas are managed by profile::projects::experiment.
  #
  # For top-level projects, $parent will be $root, so this block is skipped
  # because File[$root] is already managed by profile::projects.
  if $parent != $root and ($experiment_root == undef or $parent != $experiment_root) {
    ensure_resource('file', $parent, {
        ensure  => directory,
        owner   => 'root',
        group   => $project_group,
        mode    => $defaults.get('mode_root', '2750'),
        require => File[$root],
    })
  }

  file { $path:
    ensure  => directory,
    owner   => $sponsor,
    group   => $project_group,
    mode    => $defaults.get('mode_root', '2750'),
    require => File[$parent],
  }

  exec { "set_cephfs_quota_${title}":
    command => "/usr/bin/setfattr -n ceph.quota.max_bytes -v ${quota_bytes} ${path}",
    unless  => "/usr/bin/getfattr -n ceph.quota.max_bytes ${path} 2>/dev/null | /bin/grep -q ${quota_bytes}",
    require => File[$path],
  }

  $token = regsubst($title, '[^A-Za-z0-9._-]', '_', 'G')
  $aclfile = "/etc/dice/acl/projects/project_${token}.acl"
  $allow_writers = ! $writers.empty

  file { $aclfile:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('profile/projects/acl.epp', {
        'path'              => $path,
        'group'             => $project_group,
        'extra_read_groups' => $extra_read_groups,
        'writers'           => $writers,
        'allow_writers'     => $allow_writers,
    }),
    require => File['/etc/dice/acl/projects'],
  }

  exec { "apply_acl_${aclfile}":
    command => "/usr/bin/setfacl --set-file ${aclfile} ${path}",
    unless  => "/usr/bin/getfacl -c --absolute-names --no-effective ${path} | /usr/bin/diff -u -B - ${aclfile} >/dev/null",
    path    => ['/usr/bin','/bin'],
    require => [File[$path], File[$aclfile]],
  }

  file { "${path}/${defaults.get('readme_filename', 'README.md')}":
    ensure  => file,
    owner   => $sponsor,
    group   => $project_group,
    mode    => '0644',
    content => epp('profile/projects/readme.md.epp', {
        'title'                => $title,
        'description'          => $description,
        'sponsor'              => $sponsor,
        'quota_gib'            => $quota_gib_2,
        'quota_bytes'          => $quota_bytes,
        'effective_read_group' => $effective_read_group,
        'extra_read_groups'    => $extra_read_groups,
        'writers'              => $writers,
    }),
    require => [File[$path], File[$aclfile]],
  }
}
