## ⏩ Upgrade the software

You can upgrade the software with `./install.sh`.
It finds a new version of Restic rest server and brypt and installs it in the current directory.

Udate scripts:

* execute steps im "Get sources" to download the current version from Github

Upgrade restic rest server.

* Execute `sudo ./install.sh` to download the latest binaries

After update/ upgrade:

* run `sudo ./rest_server.sh restart` to restart the restic rest service

If a new Restic rest version was found then delete 

* folder `rest-server_<old-version>*`
* file `rest-server_<old-version>*.tgz`

### Change in Sep 2026

The installer now installs **bcrypt-tool** in the `brypt`subfolder. It allows to use blowfish hashes in the `data/.htpasswd`.

Now you can safely switch to the option noauth=0 in `rest_server.conf`.

(1)
You need to execute 

`./useradmin.sh update <username>`

for each user and set the new password on the clients.

(2)
Set the option `noauth=0` in `rest_server.conf`.

(3)
Restart the restic server with `sudo ./rest_server.sh restart` to reread user passwords and the changes in the config file.