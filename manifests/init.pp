lookup('classes', {merge => unique}).include
include 'dummy_service'

ensure_packages(['openssh-client'], {'ensure' => 'present'})

Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

exec { 'ssh_known_host_bitbucket':
  command => 'ssh-keyscan -t rsa bitbucket.org >> /etc/ssh/ssh_known_hosts',
  unless  => 'grep bitbucket.org /etc/ssh/ssh_known_hosts',
  user    => 'root',
  require => Package['openssh-client'],
} -> class { 'r10k':
  sources => {
    'puppet' => {
      'remote'  => 'git@bitbucket.org:mygento/puppet-server.git',
      'basedir' => '/etc/puppetlabs/code/environments',
      'prefix'  => false,
    }
  },
} -> file {'/etc/r10k.yaml':
  ensure => 'link',
  target => '/etc/puppetlabs/r10k/r10k.yaml',
}

class {'r10k::webhook::config':
  use_mcollective => false,
  enable_ssl      => false,
  protected       => false,
  access_logfile  => 'stderr',
}

class {'r10k::webhook':
  use_mcollective => false,
  user            => 'root',
  group           => 'root',
  background      => false,
  require         => Class['r10k::webhook::config'],
}
