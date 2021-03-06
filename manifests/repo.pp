# == Class: logstash::repo
#
# This class exists to install and manage yum and apt repositories
# that contain logstash official logstash packages
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'logstash::repo': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Phil Fenstermacher <mailto:phillip.fenstermacher@gmail.com>
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
# * Matthias Baur <mailto:matthias.baur@dmc.de>
#
class logstash::repo {

  Exec {
    path      => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd       => '/',
  }

  case $::osfamily {
    'Debian': {
      require apt

      apt::source { 'logstash':
        location => "https://packages.elastic.co/logstash/${logstash::repo_version}/debian",
        release  => 'stable',
        repos    => 'main',
        key      => {
          'id'     => '46095ACC8548582C1A2699A9D27D666CD88E42B4',
          'source' => 'https://packages.elastic.co/GPG-KEY-elasticsearch',
        },
        include  => {
          'src' => false,
        },
      }

      Apt::Source['logstash'] -> Package<|tag == 'logstash'|>
      Class['Apt::Update'] -> Package<|tag == 'logstash'|>
    }
    'RedHat': {
      yumrepo { 'logstash':
        descr    => 'Logstash Centos Repo',
        baseurl  => "https://packages.elastic.co/logstash/${logstash::repo_version}/centos",
        gpgcheck => 1,
        gpgkey   => 'https://packages.elastic.co/GPG-KEY-elasticsearch',
        enabled  => 1,
      }

      Yumrepo['logstash'] -> Package<|tag == 'logstash'|>
    }
    'Suse' : {
      case $::operatingsystem {
        'SLES': {
          $centos_version = 'centos5'
          $gpg_key = 'GPG-KEY-elasticsearch-v3'
          $gpg_id = '465C1136'
        }
        'OpenSuSE': {
          $centos_version = 'centos'
          $gpg_key = 'GPG-KEY-elasticsearch'
          $gpg_id = 'D88E42B4'
        }
        default: {
          fail("Unknown Operating system (${::operatingsystem})for Suse family")
        }
      }

      zypprepo { 'logstash':
        baseurl     => "https://packages.elastic.co/logstash/${logstash::repo_version}/${centos_version}/",
        enabled     => 1,
        autorefresh => 1,
        name        => 'logstash',
        gpgcheck    => 1,
        gpgkey      => "https://packages.elastic.co/${gpg_key}",
        type        => 'yum',
      }

      # Workaround until zypprepo allows the adding of the keys
      # https://github.com/deadpoint/puppet-zypprepo/issues/4
      exec { 'logstash_suse_import_gpg':
        command =>  "wget -q -O /tmp/RPM-GPG-KEY-elasticsearch https://packages.elastic.co/${gpg_key}; rpm --import /tmp/RPM-GPG-KEY-elasticsearch; rm /tmp/RPM-GPG-KEY-elasticsearch",
        unless  =>  "test $(rpm -qa gpg-pubkey | grep -i \"${gpg_id}\" | wc -l) -eq 1 ",
      }

      Exec['logstash_suse_import_gpg'] ~> Zypprepo['logstash'] -> Package<|tag == 'logstash'|>
    }
    default: {
      fail("\"${module_name}\" provides no repository information for OSfamily \"${::osfamily}\"")
    }
  }
}
