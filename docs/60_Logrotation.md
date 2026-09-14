## Logrotation

The installer creates a file for restic http server in /etc/logrotate.d/.

### OLD method (which still works):

`./rest_server.sh logrotate` detects existance of restic config file in /etc/logrotate.d/. 

If it fails the old way works only once per day - it will rotate the logfile with the date as extension.
Rotated logs older 7d will be deleted.

### To run the logrotation regulary

In the synology web ui go to the task planner and let execute a custom script daily.

The Script to execute is

`/volume1/opt/restic/rest_server.sh logrotate`
or
`/usr/local/etc/rc.d/rest_server.sh logrotate`

In the beginning you can activate to send an email of each execution. Test the job with run now and then check your email inbox.
