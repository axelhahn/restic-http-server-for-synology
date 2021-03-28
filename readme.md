# Restic Http Server on Synology NAS

## Description

A set of bash scripts to 

* Install rest http server on a Synology NAS.
* Service handling: start/stop/status of server
* A user administration for access private repos handles user entries in [webroot]/.htpasswd

## License

GNU GP 3.0

## Installation

### Prepare

Web based stuff:

* WebLogin to your Synology with an admin user
* Activate DDNS for your NAS
* Activate ssl certificate for your NAS - what is using Let's Encrypt

Via SSH console:

* Login to your Synology with an admin account
* Make a sudo -i to become root
* Create a directory, i.e. /volume1/opt/restic
* Copy the files of the project there

The result is something like that:

```
# ls -1
install.sh
rest_server.conf.dist
rest_server.sh
useradmin.sh
```

### Install Binary and basic config

Execute `./install.sh` to download the required binary and initialize the service.

The reuslt is

```
# ls -1
data
install.sh
log
rest-server
rest-server_0.10.0_linux_arm64
rest-server_0.10.0_linux_arm64.tar.gz
rest_server.conf
rest_server.conf.dist
rest_server.sh
useradmin.sh
```

### see the config

There is no change at this point ... but have a look:

```
root@nas:/volume1/opt/restic# cat rest_server.conf
# ======================================================================
#
# HTTP REST SERVER CONFIG FILE
#
#
# a relative path is relative to restic_server.sh - or use absolute
#
# ======================================================================



# where to find binary of http rest server - no need to change
dir_server=rest-server

# place of key and cert; it is specific for Synonlogy NAS - no need to change
dir_cert=/usr/syno/etc/certificate/system/default


# listen port of rest server; 8000 is default
listen=':8000'

# webroot of backup data
dir_data=data

# path of log
logfile=log/restic-server.log


# ----------------------------------------------------------------------
#
# flags for restic server process
#
appendonly=0
privaterepos=1
noauth=1


# ----------------------------------------------------------------------
#
# user admin
#
# length of user password for a new user
pwlength=32

# ----------------------------------------------------------------------
```

### create a user

The default config activates private repos (see restic http doc for description).
In short: a user [user] gets access to [backup-url]:[port]/[user]/ only ... with its own password.

Execute `./useradmin.sh add USERNAME` to create (or update) a user with a generated password (32 chars by default).
Execute `./useradmin.sh status` to see all users and their used size.

### start service

Execute `./rest_server.sh start` to start server.

## Status

In short: work in progress.

DONE

* installation process for binary and initial running config
* use https (using Let's Encrypt certicate of the system)
* handle service start|stop|status
* configure service behaviour in a conf file
* add/ update users for private repositories
* autostart service on reboot
* handle users with encrypted passwort in .htpasswd 

TODO

* service runs as root - not as unprivileged http user
* logrotation - currently it log into one log file ... which is just growing
* log format - the output for a request is quite basic
* no package ... it is a manual way so far
