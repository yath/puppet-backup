# XXX remove the $nomirror=false when all exported resources have $nomirror
# set
define backup::serveruser($fqdn = $title, $user, $sshkey, $nomirror = false) {
    include 'backup::params'

    if $nomirror {
        validate_re($user, "^${backup::params::userprefix_nomirror}")
        $backupdir = "${backup::params::backuproot_nomirror}/${user}"
    } else {
        validate_re($user, "^${backup::params::userprefix}")
        $backupdir = "${backup::params::backuproot}/${user}"
    }

    user{$user:
        ensure  => present,
        comment => "backup user for ${fqdn}",
        home    => $backupdir,
    }

    file{$backupdir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file{"${backupdir}/${backup::params::duplicity_subdir}":
        ensure  => directory,
        owner   => $user,
        mode    => '0755',
        require => User[$user],
    }

    file{"${backupdir}/.ssh":
        ensure => directory,
        owner  => $user,
        mode   => '0710',
    }

    file{"${backupdir}/.ssh/authorized_keys":
        ensure  => present,
        owner   => $user,
        mode    => '0610',
        content => $sshkey,
    }
}
