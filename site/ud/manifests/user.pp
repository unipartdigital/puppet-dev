# @summary
#   Create a local user
#
# This is intended to be invoked automatically by
# [`ud::profile::base`](#udprofilebase) based on the YAML dictionary
# [`ud::users`](USERS.md).  You should not need to use this defined
# type directly.
#
# @param name
#   User name
#
# @param ensure
#   Desired state ('present' or 'absent')
#
# @param sudo
#   User should be able to execute commands as root
#
# @param keys
#   Optional list of SSH authorized keys
#
# @param groups
#   Optional list of supplementary groups
#
define ud::user (
  String $ensure = 'present',
  Boolean $sudo = true,
  Array[String] $keys = [],
  Array[String] $groups = [],
)
{

  # Include base requirements
  #
  include ud::user::base

  # Home directory
  #
  $home = $name ? { 'root' => '/root', default => "/home/${name}" }

  # Extra groups
  #
  $extras = ($sudo and $name != 'root') ? { true => ['wheel'], false => [] }

  # User account
  #
  user { $name:
    ensure => $ensure,
    home => $home,
    managehome => true,
    purge_ssh_keys => true,
    membership => 'minimum',
    groups => $groups + $extras,
  }

  # SSH key
  #
  $keys.each |String $key| {

    $key_split = split($key, /\s+/)

    # User key
    #
    ssh_authorized_key { "${key_split[2]} (${name})":
      ensure => $ensure,
      user => $name,
      type => $key_split[0],
      key => $key_split[1],
    }

  }

  # Create virtual resource for instantiation elsewhere
  #
  if ($ensure == 'present') {
    @ud::postgresql::localuser { $name:
      sudo => $sudo,
      home => $home,
    }
    @ud::mysql::localuser { $name:
      sudo => $sudo,
      home => $home,
    }
  }

}
