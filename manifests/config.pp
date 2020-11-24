#
# @summary Install and configure Apache auth_mellon
#
define mellon::config
(
  String                  $sp_metadata,
  String                  $idp_metadata,
  String                  $sp_private_key,
  String                  $sp_cert,
  String                  $location = '/',
  Optional[String]        $subdir = undef,
  Optional[Array[String]] $melloncond = undef,
  Optional[Array[String]] $mellonsetenvnoprefix = undef,
  Optional[String]        $ignore_location = undef,
  Optional[String]        $ignore_location_ip = undef,
)
{
  include ::mellon

  include ::apache::params

  # Get some parameters from puppetlabs-apache to avoid reinventing the wheel
  $httpd_dir = $::apache::params::httpd_dir
  $apache_group = $::apache::params::group

  if ($ignore_location) and (!$ignore_location_ip) {
    fail('ERROR: $ignore_location_ip cannot be unset when $ignore_location is set')
  }

  # For now, this only allow simple or'ed conditions
  if $melloncond {
    $mellonconds = $melloncond[0, -2].map | $x | { "${x} [OR]" } <<  $melloncond[-1]
  } else {
    $mellonconds = undef
  }

  if $subdir {
    $mellon_dir = "${httpd_dir}/mellon/${subdir}"
    $mellon_endpoint_path = "/${subdir}/mellon"

    file { $mellon_dir:
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0755',
      require => Class['::mellon'],
    }
  } else {
    $mellon_dir = "${httpd_dir}/mellon"
    $mellon_endpoint_path = '/mellon'
  }

  file {
    default:
      ensure  => 'present',
      owner   => 'root',
      group   => $apache_group,
      mode    => '0640',
      require => File[$mellon_dir],
    ;
    ["${mellon_dir}/idp_metadata.xml"]:
      content => $idp_metadata,
    ;
    ["${mellon_dir}/sp_metadata.xml"]:
      content => $sp_metadata,
    ;
    ["${mellon_dir}/sp-private-key.pem"]:
      content => $sp_private_key,
    ;
    ["${mellon_dir}/sp-cert.pem"]:
      content => $sp_cert,
    ;
  }

  $mellon_variable = "mellon_${title}"

  # We need to use an EPP template as the file resource is created in a different
  # namespace.
  $epp_params = { 'location'             => $location,
                  'mellon_endpoint_path' => $mellon_endpoint_path,
                  'mellon_dir'           => $mellon_dir,
                  'melloncond'           => $melloncond,
                  'mellonconds'          => $mellonconds,
                  'mellon_variable'      => $mellon_variable,
                  'mellonsetenvnoprefix' => $mellonsetenvnoprefix,
                  'ignore_location'      => $ignore_location,
                  'ignore_location_ip'   => $ignore_location_ip, }

  ::apache::custom_config { "mellon-${title}":
    content => epp('mellon/mellon.conf.epp', $epp_params),
    require => Class['::apache'],
  }
}
