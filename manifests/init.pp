# Class: supervisor
#
# Usage:
#   include supervisor
#
#
# TODO: configurations pass as parameters
class supervisor {

  # TODO: support debian installations
  case $::osfamily {
    redhat: {
      $pkg_setuptools = 'python-setuptools'
    }
    # debian: {
    #   $pkg_setuptools = 'python-setupdocs'
    # }
    default: { fail("ERROR: ${::osfamily} based systems are not supported!") }
  }

  package { $pkg_setuptools: ensure => installed, }

  # let's stick with v3.0 for now
  exec { 'easy_install-supervisor':
    command => '/usr/bin/easy_install supervisor==3.0',
    creates => '/usr/bin/supervisord',
    user    => 'root',
    require => Package[$pkg_setuptools],
  }

  # install start/stop script
  # TODO: debian support
  file { '/etc/init.d/supervisord':
    source => 'puppet:///modules/supervisor/redhat.supervisord',
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
    require => Exec['easy_install-supervisor'],
  }

  file { '/etc/supervisord.conf':
    ensure  => file,
    content => template('supervisor/supervisord.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec['easy_install-supervisor'],
    notify  => Service['supervisord'],
  }

  file { '/etc/supervisord.d':
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    mode => '0755',
    require => File['/etc/supervisord.conf'],
  }

  service { 'supervisord':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File['/etc/supervisord.conf'],
  }

}
