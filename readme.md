# Restic Http Server on Synology NAS

## 🔶 Description

A set of bash scripts to 

* Install rest http server on a Synology NAS.
* Service handling: start/stop/status of server
* A user administration for access to private repos; it handles user entries in [webroot]/.htpasswd (using openssl)

📄 Source: https://github.com/axelhahn/restic-http-server-for-synology \
📜 License GNU GPL 3.0 \
📗 Docs: see <https://www.axel-hahn.de/docs/restic-http-server-for-synology/>

---

Thanks go to to 

* [restic](https://github.com/restic) for the [rest-server](https://github.com/restic/rest-server)
* [shoenig](https://github.com/shoenig) for the [bcrypt-tool](https://github.com/shoenig/bcrypt-tool)
* [basti122303](https://github.com/basti122303) for adding multi-arch support 


Latest tested versions:

* Restic: 0.14.0
* on Synology DSM 7.3

## 🔷 Introduction

Restic **client**: https://restic.net/ - it is an opensource backup tool. 

It is very fast and uses deduplication. Copy a single to your client binary and use it. 
It stores backup data on (USB) disk, SFTP, S3 or other backend supported by rclone.

To use https as backend there is a **Restic server**. https://github.com/restic/rest-server

If you have a Synology NAS at home then this repository helps you to install that https backend and maintain users.

On your Windows/ Linux/ Mac OS client you additionally need to install the client and configure the backend url of the https server.

## 🖥️ Screenshots

Installer:

![Start fresh installation](docs/images/install_start.png)

User admin:

![Help of user admin](docs/images/useradmin_help.png)

## 👉 Status of this project

In short: work in progress.

DONE

* installation for binary and initial running config
* use https (using Let's Encrypt certicate of the system)
* handle service start|stop|status
* configure service behaviour in a conf file
* add/ update users for private repositories
* autostart service on reboot
* handle users with encrypted password in .htpasswd 
* logrotation; installer creates file in /etc/logrotate.d/ (if it fails you can create a cronjob)
* generate right .htacces entries with openssl to set noauth=0

TODO

* service runs as root - not as unprivileged http user
* log format - the output for a request is quite basic
* no package ... it is a manual way by scripts so far
