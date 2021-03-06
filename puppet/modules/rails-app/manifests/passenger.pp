class rails-app::passenger ($path = '/srv/apps/rails-app/current/public', $server_url, $rails_env) {
  file { "/etc/apache2/sites-available/$server_url":
    ensure => 'present',
    content => template('rails-app/passenger-app.erb'),
    require => Package['apache2'],
    notify => Service['apache2'],
  }

  file { "/etc/apache2/sites-enabled/000-default":
    ensure => "/etc/apache2/sites-available/$server_url",
    require => File["/etc/apache2/sites-available/$server_url"],
    notify => Service['apache2'],
  }

  if $use_ssl {
    file { '/etc/apache2/mods-enabled/ssl.conf':
      ensure => 'link',
      target => '/etc/apache2/mods-available/ssl.conf',
      require => Package['apache2'],
      notify => Service['apache2'],
    }

    file { '/etc/apache2/mods-enabled/ssl.load':
      ensure => 'link',
      target => '/etc/apache2/mods-available/ssl.load',
      require => Package['apache2'],
      notify => Service['apache2'],
    }
  }
}