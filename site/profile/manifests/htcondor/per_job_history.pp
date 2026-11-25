# Archive of finished jobs: one history file per job, written by the schedd.
#
# PER_JOB_HISTORY_DIR makes a schedd write the ad of every job that leaves its
# queue into its own file (history.<cluster>.<proc>). The files are not rotated
# and nothing reads them yet: they are an archive that can be re-read later
# (accounting repairs, validation, the old APEL requirement of the CE). A daily
# timer removes files older than the retention.
#
# The directory of the batch schedd (/etc/condor) is always managed. The CE has a
# second schedd (/etc/condor-ce); give `ce_dir` on the CE.
#
# Included by the CE settings and the submit profile; add it to the node data of
# any other schedd that needs it. It has its own reconfig execs so it does not
# depend on the other HTCondor profiles.
#
# @param dir
#   Per-job history directory of the batch schedd.
# @param ce_dir
#   Per-job history directory of the CE schedd. Unset: the CE schedd is not
#   configured.
# @param retention_days
#   Files older than this many days (file mtime = when the job left the queue)
#   are deleted by the daily cleanup.
class profile::htcondor::per_job_history (
  Stdlib::Absolutepath $dir = '/var/lib/condor/per-job-history',
  Optional[Stdlib::Absolutepath] $ce_dir = undef,
  Integer[1] $retention_days = 365,
) {
  $dirs = [$dir] + ($ce_dir ? { undef => [], default => [$ce_dir] })

  file { $dirs:
    ensure => directory,
    owner  => 'condor',
    group  => 'condor',
    mode   => '0750',
  }

  exec { 'per_job_history_condor_reconfig':
    command     => 'condor_reconfig',
    refreshonly => true,
    path        => ['/usr/sbin','/usr/bin','/sbin','/bin'],
  }

  file { '/etc/condor/config.d/64-per-job-history.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "# Managed by Puppet (profile::htcondor::per_job_history)\nPER_JOB_HISTORY_DIR = ${dir}\n",
    require => File[$dir],
    notify  => Exec['per_job_history_condor_reconfig'],
  }

  if $ce_dir {
    exec { 'per_job_history_condor_ce_reconfig':
      command     => 'condor_ce_reconfig',
      refreshonly => true,
      path        => ['/usr/sbin','/usr/bin','/sbin','/bin'],
    }

    file { '/etc/condor-ce/config.d/64-per-job-history.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "# Managed by Puppet (profile::htcondor::per_job_history)\nPER_JOB_HISTORY_DIR = ${ce_dir}\n",
      require => File[$ce_dir],
      notify  => Exec['per_job_history_condor_ce_reconfig'],
    }
  }

  $find_lines = $dirs.map |$d| {
    "ExecStart=/usr/bin/find ${d} -maxdepth 1 -type f -name 'history.*' -mtime +${retention_days} -delete"
  }

  systemd::unit_file { 'htcondor-per-job-history-cleanup.service':
    content => "# Managed by Puppet (profile::htcondor::per_job_history)\n[Unit]\nDescription=Delete per-job HTCondor history files older than ${retention_days} days\n\n[Service]\nType=oneshot\n${find_lines.join("\n")}\n",
  }

  systemd::unit_file { 'htcondor-per-job-history-cleanup.timer':
    content => "# Managed by Puppet (profile::htcondor::per_job_history)\n[Unit]\nDescription=Daily cleanup of per-job HTCondor history files\n\n[Timer]\nOnCalendar=daily\nRandomizedDelaySec=1h\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n",
    enable  => true,
    active  => true,
    require => Systemd::Unit_file['htcondor-per-job-history-cleanup.service'],
  }
}
