# the base profile should include component modules that will be on all nodes
class profile::base {

  if $facts['os']['family'] == 'RedHat' {
    if member(['8', '9'], $::facts['os']['release']['major']) {
      # RHEL 8 or 9
      $chrony_servers = lookup('ntp::servers', Array, 'first', [])
      class { 'chrony':
        servers => $chrony_servers,
      }
    } else {
      # RHEL 7
      class { 'ntp': }
    }
    # we like automatic updates (except for kernel and on VM hosts)
    $automatic_updates = lookup('profile::base::automatic_updates', Boolean, undef, true)
    if $automatic_updates {
      class { 'yum_cron':
        apply_updates => true,
      }
    }

    $packages_to_install = lookup('profile::default::packages_to_install', Array[String], 'unique', [])
    $packages_to_remove  = lookup('profile::default::packages_to_remove', Array[String], 'unique', [])

    # to be used for packages that need to be added to specific nodes/profiles/roles
    $extra_packages_to_install = lookup('profile::extra::packages_to_install', Array[String], 'deep', [])

    package { $packages_to_install:
      ensure          => 'present',
      install_options => '--enablerepo=epel',
    }
    package { $extra_packages_to_install:
      ensure          => 'present',
      install_options => '--enablerepo=epel',
    }

    package { $packages_to_remove: ensure => 'absent', }

    class { 'mlocate':
      period            => 'daily',
      prunenames        => ['.git', 'CVS', '.hg', '.svn'],
      prune_bind_mounts => true,
      prunepaths        => [
        '/afs', '/media', '/mnt', '/net', '/sfs', '/tmp', '/udev', '/var/cache/ccache',
        '/var/spool/cups', '/var/spool/squid', '/var/tmp', '/var/lib/yum/yumdb', '/var/lib/dnf/yumdb', '/var/lib/ceph',
        '/condor',
        '/dmlite',
        '/dpm',
        '/docker_registry',
        '/exports',
        '/gpfs',
        '/gpfs_phys',
        '/grid',
        '/h1',
        '/h2',
        '/h3',
        '/h4',
        '/h5',
        '/h6',
        '/h7',
        '/h8',
        '/h9',
        '/h10',
        '/h11',
        '/h12',
        '/hdfs',
        '/var/spool/arc',
        '/var/cache/cvmfs2',
        '/cephfs',
        '/cvmfs',
      ],
      prunefs           => [
        '9p', 'afs', 'anon_inodefs', 'auto', 'autofs', 'bdev', 'binfmt_misc',
        'cgroup', 'cifs', 'coda', 'configfs', 'cpuset', 'debugfs', 'devpts',
        'ecryptfs', 'exofs', 'fuse', 'fusectl', 'gfs', 'gfs2', 'hugetlbfs',
        'inotifyfs', 'iso9660', 'jffs2', 'lustre', 'mqueue', 'ncpfs', 'nfs',
        'nfs4', 'nfsd', 'pipefs', 'proc', 'ramfs', 'rootfs', 'rpc_pipefs',
        'securityfs', 'selinuxfs', 'sfs', 'sockfs', 'sysfs', 'tmpfs', 'ubifs',
        'udf', 'usbfs',
        'ceph', 'fuse.ceph',
      ],
    }
  }
  $disable_cbsensor = lookup('profile::base::disable_cbsensor', Boolean, undef, false)
  unless $disable_cbsensor {
    class { 'cbsensor': }
  }
}
