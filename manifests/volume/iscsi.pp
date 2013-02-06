#
class cinder::volume::iscsi (
  $iscsi_ip_address,
  $volume_group      = 'cinder-volumes',
  $iscsi_helper      = 'tgtadm'
) {

  include cinder::params

  cinder_config {
    'DEFAULT/iscsi_ip_address': value => $iscsi_ip_address;
    'DEFAULT/iscsi_helper':     value => $iscsi_helper;
    'DEFAULT/volume_group':     value => $volume_group;
   }

  case $iscsi_helper {
    'tgtadm': {
      package { 'tgt':
        name   => $::cinder::params::tgt_package_name,
        ensure => present,
      }

      if($::osfamily == 'RedHat') {
        file_line { 'cinder include':
          path => '/etc/tgt/targets.conf',
          line => "include /etc/cinder/volumes/*",
          match => '#?include /',
          require => Package['tgt'],
          notify => Service['tgtd'],
        }
      }

      service { 'tgtd':
        name    => $::cinder::params::tgt_service_name,
        ensure  => running,
        enable  => true,
        require => Class['cinder::volume'],
      }
    }

    default: {
      fail("Unsupported iscsi helper: ${iscsi_helper}.")
    }
  }

  # set up the actual iscsi support for the OS
  if($::operatingsystem == 'Ubuntu') {
    package{ [ 'iscsitarget' ,
               'open-iscsi', 'iscsitarget-dkms', 
               "linux-headers-$::kernelrelease", ]:
         ensure => 'present',
    }

    file { '/etc/default/iscsitarget':
       ensure => present,
       owner => 'root',
       group   => 'root',
       mode    => '644',
       content => "ISCSITARGET_ENABLE=true\n# ietd options\n# See ietd(8) for details\nISCSITARGET_OPTIONS=\"\"",
       notify => Service['iscsitarget'],
       require => Package['iscsitarget'],
    }

    service { 'iscsitarget':
     ensure => running,
     enable => true,
    }

   service { 'open-iscsi':
     ensure => running,
     enable => true,
   }

  }

}
