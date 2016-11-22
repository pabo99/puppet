class omegaup::developer_environment (
	$root,
	$user,
	$mysql_host,
	$mysql_user,
	$mysql_password,
) {
	include omegaup::java
	include pear

	# Packages
	package { ['vim', 'phpunit', 'openssh-client', 'gcc', 'g++', 'python3',
						 'clang-format-3.7', 'python-pip', 'silversearcher-ag',
						 'ca-certificates', 'meld', 'vim-gtk']:
		ensure  => present,
	}
	pear::package { "PHP_CodeSniffer":
		version => "2.6.2",
	}

	# Definitions
	define remote_file($source=undef, $mode='0644', $owner=undef, $group=undef) {
		exec { "wget_${title}":
			command => "/usr/bin/wget -q ${source} -O ${title}",
			creates => $title,
		}

		file { $title:
			ensure  => 'file',
			mode    => $mode,
			owner   => $owner,
			group   => $group,
			require => Exec["wget_${title}"],
		}
	}

	# SBT
	exec { 'update-ca-certificates':
		command => '/usr/sbin/update-ca-certificates -f',
		creates => "${::omegaup::java::jre_directory}/lib/security/cacerts",
		require => [Package['ca-certificates'], Package[$::omegaup::java::jre_package]],
	}
	file { '/usr/bin/sbt':
		ensure  => 'file',
		source  => 'puppet:///modules/omegaup/sbt',
		owner   => 'root',
		group   => 'root',
		mode    => 'a+x',
		require => Exec['update-ca-certificates'],
	}
	remote_file { '/usr/bin/sbt-launch.jar':
		source => 'https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.7/sbt-launch.jar',
	}

	# Test setup
	file_line { 'hhvm include_path':
		line    => 'include_path = /usr/share/php:.',
		path    => '/etc/hhvm/php.ini',
	}
	config_php { 'test settings':
		settings => {
			'OMEGAUP_DB_USER'     => $mysql_user,
			'OMEGAUP_DB_HOST'     => $mysql_host,
			'OMEGAUP_DB_PASS'     => $mysql_password,
			'OMEGAUP_DB_NAME'     => 'omegaup-test',
			'OMEGAUP_SSLCERT_URL' => '/etc/omegaup/frontend/certificate.pem',
			'OMEGAUP_CACERT_URL'  => '/etc/omegaup/frontend/certificate.pem',
		},
		ensure   => present,
	  path     => "${root}/frontend/tests/test_config.php",
		owner    =>  $user,
		group    =>  $user,
	}
	config_php { 'developer settings':
		settings => {
			'OMEGAUP_DEVELOPMENT_ENVIRONMENT' => 'true',
		},
		ensure   => present,
	  path     => "${root}/frontend/server/config.php",
		require  => Config_php['default settings'],
	}
	file { "${root}/frontend/tests/controllers/omegaup.log":
		ensure  => 'file',
		owner   => $user,
		group   => $user,
	}
	file { ["${root}/frontend/tests/controllers/problems",
			"${root}/frontend/tests/controllers/submissions"]:
		ensure  => 'directory',
		owner   => $user,
		group   => $user,
	}
}
