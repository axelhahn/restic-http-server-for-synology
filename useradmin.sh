#!/usr/bin/bash
# ============================================================
#
# USER ADMIN FOR .htaccess OF RESTIC HTTP SERVER
# ON SYNOLOGY NAS
#
# This script updates the .htpasswd without apache htpasswd
# by using openssl
#
# ------------------------------------------------------------
# License: GNU GPL 3.0
# ------------------------------------------------------------
# 2021-03-29  www.axelhahn.de  init ... but WIP
# 2021-05-09  www.axelhahn.de  added delete param
# 2026-09-12  www.axelhahn.de  use blowfish password hashes
# ============================================================


#defaults
typeset -i privaterepos=1
typeset -i noauth=0
typeset -i pwlength=32


# ------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------

function _generate_password(){
        head /dev/urandom | tr -dc A-Za-z0-9 | head -c $pwlength
}

function _encrypt_apr1(){
        openssl passwd -apr1 $1
}

function _encrypt_blowfish(){
        # python3 -c "import bcrypt; print(bcrypt.hashpw(b'$1', bcrypt.gensalt()))"
        bcrypt/bcrypt-tool hash "$1" 10 || echo "$1"
}

function _update_htpasswd(){
        local myuser=$1

        mypw=$( _generate_password )
        mypw="1GTeTXcXbw34G9uqPYGe5DVScrMSZN3v"
        # mycrpyted=$( _encrypt_apr1 "${mypw}")
        mycrpyted=$( _encrypt_blowfish "${mypw}")

        cat "${htfile}" 2>/dev/null | grep -v "^${myuser}:" >"${htfile}.tmp"
        printf "%s:%s\n" "${myuser}" "${mycrpyted}" >> ${htfile}.tmp \
                && sort "${htfile}.tmp" > "${htfile}"

        rm "${htfile}.tmp"

        if [ ! -f "${htfile}" ]; then
                echo "❌ ERROR: unable to create ${htfile}. Abort."
                exit 1
        fi
        echo
        echo "✅ OK."
}

function add(){
        local myuser=$1
        echo "ADD user '$myuser'"
        echo
        if [ -z "$myuser" ]; then
                echo -n 'Username: '
                read myuser
                if [ -z "$myuser" ]; then
                        echo "Abort."
                        exit 1
                fi
        fi

        cat "${htfile}" 2>/dev/null | grep "^${myuser}:" >/dev/null
        if [ $? -eq 0 ]; then
                echo "❌ ERROR: User already exists"
                exit 1
        fi
        echo 'Creating new user ...'

        _update_htpasswd "${myuser}"
        pwhint

}

function update(){
        local myuser=$1
        echo "UPDATE password for user '$myuser'"
        echo
        if [ -z "$myuser" ]; then
                echo -n 'Username: '
                read myuser
                if [ -z "$myuser" ]; then
                        echo "Abort."
                        exit 1
                fi
        fi

        cat "${htfile}" 2>/dev/null | grep "^${myuser}:" >/dev/null
        if [ $? -ne 0 ]; then
                echo "❌ ERROR: User does not exist: '${myuser}'"
                exit 1
        fi
        echo "Setting a new password ..."

        _update_htpasswd "${myuser}"
        pwhint
}

function pwhint(){
        echo
        echo "    (1)"
        echo "    Restart Restic rest server to re-read user data."
        echo "        sudo ./rest_server.sh restart"
        echo
        echo "    (2)"
        echo "    The generated password is:"
        echo "        $mypw"
        echo
        echo "    You cannot restore the password anymore - only set a new one."
        echo "    Copy and paste password data from screen. Now!"
        echo
        echo "    For user '${myuser}' set the environment variable RESTIC_REPOSITORY."
        echo
        echo "    In a Bourne Shell, Bash:"
        echo "      export RESTIC_REPOSITORY=rest:https://${myuser}:$mypw@[SYONOLOGY]:8000/${myuser}/"
        echo "    In other shells or Windows Batch use 'set' instead of 'export'."
        echo
}
function delete(){
        local myuser=$1
        echo "DELETE user '${myuser}'"
        echo
        if [ -z "$myuser" ]; then
                status

                echo -n 'Username to delete: '
                read myuser
                if [ -z "$myuser" ]; then
                        echo "Abort."
                        exit 1
                fi
        fi
        cat "${htfile}" 2>/dev/null | grep "^${myuser}:" >/dev/null
        if [ $? -ne 0 ]; then
                echo "❌ ERROR: user '$myuser' does not exist in ${htfile}. Use parameter 'status' to get a list of existing users."
                exit 1
        fi
        echo

        echo '--- deleting backup data:'
        test -d "$dir_data/$myuser" || echo 'SKIP: no backup data were found'
        test -d "$dir_data/$myuser" && echo "deleting $dir_data/$myuser" && rm -rf "$dir_data/$myuser"
        echo
        echo "--- removing user '${myuser}' from ${htfile}"
        cat "${htfile}" 2>/dev/null | grep -v "^${myuser}:" >"${htfile}.tmp"
        mv "${htfile}.tmp" "${htfile}" || exit 1
        echo
        echo '✅ OK.'
        echo

}
function status(){
        echo STATUS
        echo
        local tbl='%-10s %-65s %s'
        local tblline='-----------------------------------------------------------------------------------------------'
        echo '--- htpasswd file:'
        if ! ls -l $htfile 2>/dev/null; then
                echo "ERROR: The htpasswd file $htfile does not exist yet."
                echo "Run command 'add' to create a first user."
                exit 1
        fi
        echo

        typeset -i local iUsers=$( cat ${htfile} | grep "^[a-zA-Z]" | wc -l )
        echo "Users: $iUsers"
        if [ $iUsers -gt 0 ]; then
                echo
                printf "$tbl\n" 'User' 'password hash' 'used space'
                echo $tblline
                for myline in  $( cat "${htfile}" | grep "^[a-zA-Z]" )
                do
                        myuser=$( echo $myline | cut -f 1 -d ':')
                        pwhash=$( echo $myline | cut -f 2 -d ':')
                        grep -q "\$apr1\\$" <<< "$pwhash" && pwhash="$pwhash (!)"

                        test -d "$dir_data/$myuser" && mysize=$( du -hs $dir_data/$myuser )
                        test -d "$dir_data/$myuser" || mysize='[no data yet]'
                        printf "$tbl\n" "$myuser" "$pwhash" "$mysize"
                done
                echo $tblline
                if grep -q "\$apr1\\$" "${htfile}"; then
                        echo "⚠️ WARNING: password hashes found with old APR1 algorithm."
                        echo "   It is recommended to use the Blowfish algorithm instead."
                        echo "   Please update the password with command 'update'."
                fi
        else
                echo "No users found in $htfile"
                echo "Run command 'add' to create a first user."
        fi
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

cd `dirname $0`
. rest_server.conf
htfile=$dir_data/.htpasswd

# https://patorjk.com/software/taag/#p=display&f=Small+Block&t=Synology+-+Restic+Server&x=none&v=4&h=4&w=80&we=false
echo "
   ▞▀▖         ▜               ▛▀▖      ▐  ▗     ▞▀▖               
   ▚▄ ▌ ▌▛▀▖▞▀▖▐ ▞▀▖▞▀▌▌ ▌ ▄▄▖ ▙▄▘▞▀▖▞▀▘▜▀ ▄ ▞▀▖ ▚▄ ▞▀▖▙▀▖▌ ▌▞▀▖▙▀▖
   ▖ ▌▚▄▌▌ ▌▌ ▌▐ ▌ ▌▚▄▌▚▄▌     ▌▚ ▛▀ ▝▀▖▐ ▖▐ ▌ ▖ ▖ ▌▛▀ ▌  ▐▐ ▛▀ ▌  
   ▝▀ ▗▄▘▘ ▘▝▀  ▘▝▀ ▗▄▘▗▄▘     ▘ ▘▝▀▘▀▀  ▀ ▀▘▝▀  ▝▀ ▝▀▘▘   ▘ ▝▀▘▘  

📄 Source: https://github.com/axelhahn/restic-http-server-for-synology
📜 License GNU GPL 3.0


        USER ADMIN
"

test $privaterepos -eq 0 && (
        echo "⚠️ WARNING: private repos are disabled in 'rest_server.conf'."
        echo "   All Backups of all users are written into the same directory '$dir_data'."
        echo
)       
test $noauth -ne 0       || (
        echo "⚠️ WARNING: authentication is disabled in 'rest_server.conf'."
        echo "   Backup data can be accessed by all other users (but are still encrypted)."
        echo "   To fix it:"
        echo "   - create blowfish password hashes for all users with command 'add' or 'update'"
        echo "   - set 'noauth=0' in 'rest_server.conf' and restart the restic server"
        echo
)

if [ ! -x bcrypt/bcrypt-tool ]; then
        echo "⚠️ WARNING: bcrypt-tool is not installed. Please run './install.sh' first."
        echo "   Blowfish password hashes cannot be created and you need to enable"
        echo "   the unsafe option 'noauth=1' in 'rest_server.conf'."
        echo
fi

echo

case "$1" in
        add) add $2 ;;
        update) update $2 ;;
        delete) delete $2 ;;
        status) status ;;
        *)
                echo "USAGE: `basename $0` ACTION [user]"
                echo
                echo "ACTIONS:"
                echo
                echo '  status         Show status of current users and used disk size'
                echo '  add [user]     Add a new user and password.'
                echo '                 As 2nd parameter you can optionally add a username.'
                echo '                 Without given user it will be asked for interactively.'
                echo '                 If the user exists it will abort.'
                echo '  update [user]  Update the password for an existing user.'
                echo '                 As 2nd parameter you can optionally add a username.'
                echo '                 Without given user it will be asked for interactively.'
                echo '                 If the user does not exist it will abort.'
                echo '  delete [user]  Delete a user and all its backup data(!!!).'
                echo '                 Without given user you get the status and it will be asked'
                echo '                 for interactively.'
                ;;
esac

# ------------------------------------------------------------
