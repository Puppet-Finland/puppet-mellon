#
# @summary ensure that Apache auth_mellon is available
#
class mellon {

  # Get some parameters from puppetlabs-apache to avoid reinventing the wheel
  $httpd_dir = $::apache::params::httpd_dir

  include ::apache::mod::auth_mellon

  file { "${httpd_dir}/mellon":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => Class['::apache'],
  }
}
