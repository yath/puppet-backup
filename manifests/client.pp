class backup::client($include, $exclude, $verbosity, $nomirror,
    $asyncupload, $fullevery, $nolargerthan = undef, $keep = undef) {
    include 'backup::params'
    validate_array($include)
    validate_array($exclude)

    if $osfamily == 'RedHat' {
        fail('Not supported on RedHat :(')
    }

    package{['duplicity', 'python-paramiko', 'python-gobject-2']:
        ensure => present,
    }

    if $nomirror {
        $username = "${backup::params::userprefix_nomirror}${hostname}"
    } else {
        $username = "${backup::params::userprefix}${hostname}"
    }

    if $::root_rsa_sshkey != '' {
        @@backup::serveruser{$::fqdn:
            user     => $username,
            sshkey   => $::root_rsa_sshkey,
            nomirror => $nomirror,
        }
    }

    $passphrase = trocla("backup_duplicity_${::hostname}", 'plain', 'length: 32')
    $remote = "sftp://${username}@${backup::params::server}//${backup::params::duplicity_subdir}"

    $includeexclude = flatten([
        prefix($exclude, '--exclude='),
        prefix($include, '--include='),
        '--exclude=/'
    ])

    if $asyncupload {
        $extraopts = '--asynchronous-upload'
    } else {
        $extraopts = ''
    }

    file{'/root/scripts/backup-client.params':
        ensure  => present,
        mode    => '0700', # passphrase
        content => "export PASSPHRASE='${passphrase}'\nREMOTE='${remote}'\n",
        replace => false,
    }

    file{'/root/scripts/backup-client':
        ensure  => present,
        mode    => '0700',
        content => template("backup/backup-client.erb"),
    }

    cron{'backup-client':
        command => '/root/scripts/backup-client',
        hour    => 1,
        minute  => fqdn_rand(60),
    }

    # import server's rsa key to our known_hosts file
    Backup::Server_host_key <<| |>>
}
