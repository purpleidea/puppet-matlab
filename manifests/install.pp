# Matlab module by James
# Copyright (C) 2012-2013+ James Shubin
# Written by James Shubin <james@shubin.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
define matlab::install(     # $namevar matlab release version
  $iso,       # matlab iso for installation
  $licensekey,      # format: #####-#####-#####-#####
  $licensefile,     # license.lic as provided by mathworks
  $licenseagree = false,    # do you agree to license, true/false ?
  $prefix = '/usr/local'    # install prefix
) {
  include 'matlab'
  include matlab::vardir
  #$vardir = $::matlab::vardir::module_vardir # with trailing slash
  $vardir = regsubst($::matlab::vardir::module_vardir, '\/$', '')

  $install_destination = "${prefix}/MATLAB/${name}"

  # does user accept license ?
  $agree = $licenseagree ? {
    true    => 'yes',
    default => 'no',
  }

  # make folder to mount on
  file { "/mnt/matlab-${name}":
    ensure  => directory,    # make sure this is a directory
    recurse => false,   # don't manage directory
    purge   => false,     # don't purge unmanaged files
    force   => false,     # don't purge subdirs and links
    owner   => root,
    group   => root,
    mode    => '0555',     # default for iso mounts
    backup  => false,    # don't backup to filebucket
  }

  # get iso to mount
  # TODO: since there seem to be different iso's for each version, maybe
  # we should add a unique identifier based on the $iso variable here.
  file { "${vardir}/MATHWORKS-${name}.iso":
    ensure  => present,
    source  => $iso,
    owner   => root,
    group   => nobody,
    mode    => '0600',   # u=rw,go=
    backup  => false,  # don't backup to filebucket!
    alias   => "matlab_iso.${name}",
    require => File["/mnt/matlab-${name}"],
  }

  # mount!
  # TODO: replace this mount with an exec that has an:
  # onlyif => the_binary_is_not_installed so that a normal machine
  # doesn't need to have the iso mounted all the time...
  mount { "/mnt/matlab-${name}":
    ensure  => mounted,
    atboot  => true,
    device  => "${vardir}/MATHWORKS-${name}.iso",
    fstype  => 'iso9660',
    options => 'loop,ro',
    dump    => '0',    # fs_freq: 0 to skip file system dumps
    pass    => '0',    # fs_passno: 0 to skip fsck on boot
    alias   => "matlab_mount.${name}",
    require => [File["matlab_iso.${name}"]],
  }

  # build installer parameters file in our scratch directory
  file { "${vardir}/installer_input.txt.${name}":
    ensure  => present,
    content => template('matlab/installer_input.txt.erb'),
    owner   => root,
    group   => nobody,
    mode    => '0600', # u=rw,go=r
    require => Mount["matlab_mount.${name}"],
    alias   => "matlab_input.{${name}}",
  }

  # install matlab
  exec { "/mnt/matlab-${name}/install -inputFile ${vardir}/installer_input.txt.${name}":
    logoutput => on_failure,
    creates   => $install_destination,  # when this folder appears, we assume it got installed
    require   => File["matlab_input.{${name}}"],
    alias     => "matlab_install.${name}",
  }

  # create 'licenses' directory
  file { "${install_destination}/licenses/":
    ensure  => directory,    # make sure this is a directory
    recurse => true,    # recursively manage directory
    purge   => true,      # purge all unmanaged files
    force   => true,      # also purge subdirs and links
    owner   => root,
    group   => root,
    mode    => '0644',
    backup  => false,    # don't backup to filebucket
    require => Exec["matlab_install.${name}"],
  }

  # copy over license file to activate
  file { "${install_destination}/licenses/license.lic":
    ensure  => present,
    source  => $licensefile,
    owner   => root,
    group   => nobody,
    # TODO: is there a worry that someone will steal the license ?
    mode    => '0644',   # u=rw,g=r,o=r
    require => File["${install_destination}/licenses/"],
  }
}
