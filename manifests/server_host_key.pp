define backup::server_host_key ($fqdn = $title, $ipaddress6, $key) {
    exec{'ssh-keygen -H':
        command     => 'ssh-keygen -H -f /root/.ssh/known_hosts',
        refreshonly => true,
    }

    # we can't use stdlib's file_line here as it wouldn't find the line because
    # it gets hashed afterwards anyway...
    exec{"known_hosts entry for ${fqdn}":
        command => "echo '${fqdn},${ipaddress6} ssh-rsa ${key}' >> /root/.ssh/known_hosts",
        unless  => "grep -qF '${key}' /root/.ssh/known_hosts",
        notify  => Exec['ssh-keygen -H'],
    }
}
