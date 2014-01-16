class backup::server {
    include 'backup::params'

    package{['sshfs', 'rsync']:
        ensure => present,
    }

    file{'/root/scripts/backup-server':
        ensure => present,
        mode   => '0700',
        source => 'puppet:///modules/backup/backup-server',
    }

    cron{'backup-server':
        command => '/root/scripts/backup-server',
        hour    => 3,
        minute  => 5,
    }

    augeas{'sshd_config subsystem sftp':
        context => '/files/etc/ssh/sshd_config',
        changes => 'set Subsystem/sftp internal-sftp',
    }

    # that's even more awkward with augeas because match might be
    # an array or a directory... so just grep and append here
    $magic = "OIjdjvfdlksdsfoiOI"
    $command = "cat <<EOF >> /etc/ssh/sshd_config
Match User ${backup::params::userprefix}*
    # this needs to be found by puppet: ${magic}
    ChrootDirectory ${backup::params::backuproot}/%u
    ForceCommand internal-sftp
EOF
service ssh reload
"
    exec{'sshd_config match backup users':
        command => $command,
        unless  => "grep -qF ${magic} /etc/ssh/sshd_config",
    }

    # and the same for nomirror backups
    $magic_nomirror = "POiksOQWkjddsQ8"
    $command_nomirror = "cat <<EOF >> /etc/ssh/sshd_config
Match User ${backup::params::userprefix_nomirror}*
    # this needs to be found by puppet: ${magic_nomirror}
    ChrootDirectory ${backup::params::backuproot_nomirror}/%u
    ForceCommand internal-sftp
EOF
service ssh reload
"
    exec{'sshd_config match backup users_nomirror':
        command => $command_nomirror,
        unless  => "grep -qF ${magic_nomirror} /etc/ssh/sshd_config",
    }

    @@backup::server_host_key{$::fqdn:
        ipaddress6 => $::ipaddress6,
        key        => $::sshrsakey,
    }

    Backup::Serveruser <<| |>>
}
