# Class: supervisor
#
# Usage:
#   include supervisor
#
#   class { 'supervisor':
#     include_superlance      => false,
#     enable_http_inet_server => true,
#   }

class supervisor (
  $version                  = '3.1.2',
  $include_superlance       = true,
  $enable_http_inet_server  = false,
) {

  case $::osfamily {
    redhat: {
      if $::operatingsystem == 'Amazon' {
        $pkg_setuptools = 'python26-pip'
        $path_config    = '/etc'
      }
      else {
        $pkg_setuptools = 'python-pip'
        $path_config    = '/etc'
      }
    }
    debian: {
      $pkg_setuptools = 'python-pip'
      $path_config    = '/etc'
    }
    default: { fail("ERROR: ${::osfamily} based systems are not supported!") }
  }

  package { $pkg_setuptools: ensure => installed, }

  package { 'supervisor':
    ensure   => '3.1.2',
    provider => 'pip'
  }

  # install start/stop script
  file { '/etc/init.d/supervisord':
    source => "puppet:///modules/supervisor/${::osfamily}.supervisord",
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/var/log/supervisor':
    ensure  => directory,
    purge   => true,
    backup => false,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    require => Package['supervisor'],
  }

  file { "${path_config}/supervisord.conf":
    ensure  => file,
    content => template('supervisor/supervisord.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['supervisor'],
    notify  => Service['supervisord'],
  }

  file { "${path_config}/supervisord.d":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${path_config}/supervisord.conf"],
  }

  service { 'supervisord':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File["${path_config}/supervisord.conf"],
  }

  if $include_superlance {
    package { 'superlance':
      ensure   => installed,
      provider => 'pip',
      require  => Package['supervisor'],
    }
  }

}
