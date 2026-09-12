## ⚙️ See the config

The configuration is in the file `rest_server.conf`.

| Variable     | Type    | Description
|---           | ---     | ---
| dir_server   | string  | where to find binary of http rest server - no need to change <br>default: "rest-server"
| dir_cert     | string  | place of key and cert; it is specific for Synonlogy NAS - no need to change<br>default: "/usr/syno/etc/certificate/system/default"
| listen       | string  | listen port of rest server<br>default: ":8000"
| dir_data     | string  | webroot of backup data<br>default: "data"
| logfile      | string  | path of log<br>default: "log/restic-server.log"
| appendonly   | integer | flag: append only backup data; add `--append-only` parameter. A client cannot delete any backup data<br>default: 0
| privaterepos | integer | flag: activate private repos; add `--private-repos` parameter. There = one repo for each created user to separate backup data<br>default: 1
| noauth       | integer | flag: deactivate authentication; add `--no-auth` parameter<br>default: 0
| pwlength     | integer | length of user password for a new user<br>default: 32

