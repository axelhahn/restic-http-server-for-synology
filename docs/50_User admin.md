## Define users

### Show help

```txt
./useradmin.sh

(...)

USAGE: useradmin.sh ACTION [user]

ACTIONS:

  status         Show status of current users and used disk size
  add [user]     Add a new user and password.
                 As 2nd parameter you can optionally add a username.
                 Without given user it will be asked for interactively.
                 If the user exists it will abort.
  update [user]  Update the password for an existing user.
                 As 2nd parameter you can optionally add a username.
                 Without given user it will be asked for interactively.
                 If the user does not exist it will abort.
  delete [user]  Delete a user and all its backup data(!!!).
                 Without given user you get the status and it will be asked
                 for interactively.

```

### Show status

Show status of current users and used disk size.
It shows warnings if 

* noauth or privaterepos are set in an unsecure way or 
* an old (unusable) hash was found

### Add user

To add a new user execute `./useradmin.sh add USERNAME` to create a user with a generated password (32 chars by default).
Copy and paste the shown password in the output to your restic client config. The password visible only once.

### Delete user

Delete a user and remove aLl its backup data.

### Update user

Update the password for an existing user.
