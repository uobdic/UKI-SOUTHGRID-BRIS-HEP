# Site-owned configuration of the HTCondor-CE and its schedd (lcgce0x).
#
# Package-owned files are not managed here. Reloads: condor_ce_reconfig for
# /etc/condor-ce files, condor_reconfig for /etc/condor files.
#
# @param accounting_map
#   Ordered entries for the schedd AssignAccountingGroup map. Each entry has
#   `pattern` (owner name or /regex/), `group` (accounting group, or a comma
#   separated list) and `vo` (the supported VO it serves, used for the check).
# @param default_group
#   Fallback accounting group, last line of the map.
# @param unmapped_vos_ok
#   Supported VOs that are deliberately left to the fallback group.
class profile::htcondor::ce_settings (
  Array[Hash] $accounting_map = [],
  String[1] $default_group = 'group_physics',
  Array[String] $unmapped_vos_ok = [],
) {
  # Warn about supported VOs without an accounting group mapping.
  $site_info = lookup('site::site_info', Hash, 'first', {})
  $supported_vos = $site_info['supported_vos'] ? {
    undef   => [],
    default => $site_info['supported_vos'],
  }
  $mapped_vos = $accounting_map.map |$entry| { $entry['vo'] }
  $missing_vos = $supported_vos - $mapped_vos - $unmapped_vos_ok
  unless $missing_vos.empty {
    warning("profile::htcondor::ce_settings: supported VOs without an accounting group mapping (they fall back to ${default_group}): ${missing_vos.join(', ')}")
  }

  exec { 'condor_ce_reconfig':
    command     => 'condor_ce_reconfig',
    refreshonly => true,
    path        => ['/usr/sbin','/usr/bin','/sbin','/bin'],
  }

  exec { 'condor_reconfig':
    command     => 'condor_reconfig',
    refreshonly => true,
    path        => ['/usr/sbin','/usr/bin','/sbin','/bin'],
  }

  # --- /etc/condor-ce/config.d --------------------------------------------
  ['42-job-router.conf', '59-site-security.conf', '98-cms-storage-binds.conf', '99-local.conf', '99-scitokens.conf', '99-vo-attributes.conf'].each |$name| {
    file { "/etc/condor-ce/config.d/${name}":
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => "puppet:///modules/profile/etc/condor-ce/config.d/${name}",
      notify => Exec['condor_ce_reconfig'],
    }
  }

  # --- /etc/condor/config.d (the CE's schedd) -----------------------------
  ['01-submit.config', '60-accounting.conf', '62-apel-specs.conf'].each |$name| {
    file { "/etc/condor/config.d/${name}":
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => "puppet:///modules/profile/etc/condor/config.d/${name}",
      notify => Exec['condor_reconfig'],
    }
  }

  file { '/etc/condor/config.d/00-site-common.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/etc/condor/00_site_common.conf',
    notify => Exec['condor_reconfig'],
  }

  file { '/etc/condor/mapfiles.d/00-local.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('profile/etc/condor/mapfiles.d-00-local.conf.epp', {
        'accounting_map' => $accounting_map,
        'default_group'  => $default_group,
    }),
    notify  => Exec['condor_reconfig'],
  }
}
