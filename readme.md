# Restic Http Server on Synology NAS

## Description

A set of bash scripts to 

* Install rest http server on a Synology NAS.
* Service handling: start/stop/status of server
* A user administration for access to private repos; it handles user entries in [webroot]/.htpasswd (using openssl)

Source: https://github.com/axelhahn/restic-http-server-for-synology

## License

GNU GP 3.0

## Introduction

Restic client: https://restic.net/ - it is an opensource backup tool. 

It is very fast and uses deduplication. Copy a single to your client binary and use it. 
It stores backup data on (USB) disk, SFTP, S3 or other backend supported by rclone.

To use https as backend there is a rest http server. https://github.com/restic/rest-server

If you have a Synology NAS at home then this repository helps you to install that https
backend and maintain users.

On your Windows/ Linux/ Mac OS client you additionally need to install the client and configure
the backend url of the https server.

## Installation

### Prepare

Web based stuff:

* Login into the web ui of your Synology with an admin user
* Activate DDNS for your NAS
* Activate ssl certificate for your NAS (what is using Let's Encrypt in the background)

Via SSH console:

* Login to your Synology with an admin account
* Make a `sudo -i` to become root
* Create a directory, i.e. `/volume1/opt/restic`
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

The installer also creates a /usr/local/etc/rc.d/rest_server.sh - which is a softlink to rest_server.sh in your
installation directory.
With that link the restic http server will start automatically if your Synology nas is (re-)booting.

### see the config

There is no need to change at this point ... but have a look:

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

### create a user for http access

The default config activates private repos (see restic http doc for description).
In short: a user [user] gets access to [backup-url]:[port]/[user]/ only ... with its own password.

Execute `./useradmin.sh add USERNAME` to create (or update) a user with a generated password (32 chars by default).
Copy and paste the shown password in the output to your restic client config. The password visible only once.

It is not possible to show the password again.

But you can repeat `./useradmin.sh add USERNAME` to set a new password and update the client config.

Execute `./useradmin.sh status` to see all users and their used size.

```
# ./useradmin.sh
USAGE: useradmin.sh [status|add]
  status        show status of current users and used disk size
  add [user]    add a new user and password.
                If the user exists it will update its password.
                As 2nd parameter you can optionally add a username.
                Without given user it will be asked for interactively.
```

### start service

`./rest_server.sh start` is our service script for start/ stop/ restart restic http and logrotation.

```
# ./rest_server.sh
USAGE: rest_server.sh [start|stop|status|restart|logrotate]
```

Execute `./rest_server.sh start` to start the restic http server.
It detects if an ssl certificate was enabled and uses https if possible.

Execute `./rest_server.sh status` to see the process with PID and full path and used port.

### logrotation

`./rest_server.sh logrotate` works only once per day and will rotate the logfile with the date as extension.
Rotated logs older 7d will be deleted.

To run the logrotation regulary:
In the synology web ui go to the task planner and let execute a custom script daily.
The Script to execute is

`/volume1/opt/restic/rest_server.sh logrotate`
or
`/usr/local/etc/rc.d/rest_server.sh logrotate`

In the beginning you can activate to send an email of each execution. Test the job with run now
and then check your email inbox.

TODO: put a file into `/etc/logrotate.d/`

## Status of this project

In short: work in progress.

DONE

* installation for binary and initial running config
* use https (using Let's Encrypt certicate of the system)
* handle service start|stop|status
* configure service behaviour in a conf file
* add/ update users for private repositories
* autostart service on reboot
* handle users with encrypted password in .htpasswd 
* logrotation; needs a cronjob

TODO

* service runs as root - not as unprivileged http user
* log format - the output for a request is quite basic
* no package ... it is a manual way by scripts so far
