# @summary
#   Managed ssh server configuration
#
# @api private
#
class ssh::server::config {
  assert_private()

  $options = $ssh::server::merged_options

  case $ssh::server::validate_sshd_file {
    true: {
      $sshd_validate_cmd = '/usr/sbin/sshd -tf %'
    }
    default: {
      $sshd_validate_cmd = undef
    }
  }

  if $ssh::server::use_augeas {
    create_resources('sshd_config', $options)
  } else {
    concat { $ssh::server::sshd_config:
      ensure       => present,
      owner        => 0,
      group        => 0,
      mode         => '0600',
      validate_cmd => $sshd_validate_cmd,
      notify       => Service[$ssh::server::service_name],
    }

    concat::fragment { 'global config':
      target  => $ssh::server::sshd_config,
      content => template("${module_name}/sshd_config.erb"),
      order   => '00',
    }
  }

  if $ssh::server::use_issue_net {
    file { $ssh::server::issue_net:
      ensure  => file,
      owner   => 0,
      group   => 0,
      mode    => '0644',
      content => template("${module_name}/issue.net.erb"),
      notify  => Service[$ssh::server::service_name],
    }

    concat::fragment { 'banner file':
      target  => $ssh::server::sshd_config,
      content => "Banner ${ssh::server::issue_net}\n",
      order   => '01',
    }
  }

  if ($ssh::server::autodetect_hostcertificates) {
    if(has_key($facts,'ssh')){
      concat::fragment{ 'autodetected host certificates':
        target  => $ssh::server::sshd_config,
        content => $facts['ssh'].keys().map |$k| {"HostCertificate /etc/ssh/ssh_host_${k}_key-cert.pub\n"}.join(''), #DEBUG: remove comment
        order   => '02',
      }
	}
  }
}
