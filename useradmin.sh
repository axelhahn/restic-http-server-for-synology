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

function add(){
        local myuser=$1
        echo
        echo 'ADD (or update) user'
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
                echo 'Creating new user ...'
        else
                echo 'Updating password of existing user ...'
        fi

        mypw=$( _generate_password )
        mycrpyted=$( _encrypt_apr1 "${mypw}")


        cat "${htfile}" 2>/dev/null | grep -v "^${myuser}:" >"${htfile}.tmp"
        echo ${myuser}:${mycrpyted} >> ${htfile}.tmp \
                &&  sort "${htfile}.tmp" > "${htfile}"

        if [ ! -f "${htfile}" ]; then
                echo "ERROR: unable to create ${htfile}. Abort."
                exit 1
        fi
        echo "OK."
        echo
        echo
        echo "(1)"
        echo "Restart rest server to re-read user data."
        echo "./rest_server.sh restart"
        echo
        echo "(2)"
        echo "The generated password is: $mypw"
        echo "You cannot restore the password anymore - only set a new one."
        echo "Copy and paste password data from screen. Now!"
        echo
        echo "For user [${myuser}] set the environment variable RESTIC_REPOSITORY."
        echo
        echo "In a Bourne Shell, Bash:"
        echo "  export RESTIC_REPOSITORY=rest:https://${myuser}:$mypw@[SYONOLOGY]:8000/${myuser}/"
        echo "In other shells or Windows Batch use [set] instead of [export]."
        echo
}
function delete(){
        local myuser=$1
        echo
        echo 'DELETE user'
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
                echo "ERROR: user [$myuser] does not exist in ${htfile}. Use parameter status to get a list of existing users."
                exit 1
        fi

        echo '--- deleting backup data:'
        test -d "$dir_data/$myuser" || echo 'SKIP: no backup data were found'
        test -d "$dir_data/$myuser" && echo "deleting $dir_data/$myuser" && rm -rf "$dir_data/$myuser"
        echo
        echo "--- removing user ${myuser} from ${htfile}"
        cat "${htfile}" 2>/dev/null | grep -v "^${myuser}:" >"${htfile}.tmp" && mv "${htfile}.tmp" "${htfile}" || exit 1
        echo 'OK.'
        echo

}
function status(){
        echo
        echo STATUS
        echo
        local tbl='%-10s %-40s %s'
        local tblline='--------------------------------------------------------------------------------'
        echo '--- htpasswd file:'
        ls -l $htfile
        echo

        typeset -i local iUsers=$( cat ${htfile} | grep "^[a-zA-Z]" | wc -l )
        echo "Users: $iUsers"
        if [ $iUsers -gt 0 ]; then
                echo
                printf "$tbl\n" 'User' 'password' 'used space'
                echo $tblline
                for myline in  $( cat ${htfile} | grep "^[a-zA-Z]" )
                do
                        myuser=$( echo $myline | cut -f 1 -d ':')
                        pwhash=$( echo $myline | cut -f 2 -d ':')
                        test -d "$dir_data/$myuser" && mysize=$( du -hs $dir_data/$myuser )
                        test -d "$dir_data/$myuser" || mysize='[no data yet]'
                        printf "$tbl\n" $myuser $pwhash "$mysize"
                done
                echo $tblline
        fi
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

cd `dirname $0`
. rest_server.conf
htfile=$dir_data/.htpasswd


test $privaterepos -eq 0 && echo 'WARNING: private repos are disabled in rest_server.conf.'
test $noauth -ne 0       || echo 'WARNING: authentication is disabled in rest_server.conf.'

case "$1" in
        add) add $2 ;;
        delete) delete $2 ;;
        status) status ;;
        *)
                echo "USAGE: `basename $0` [status|add|delete]"
                echo '  status         Show status of current users and used disk size'
                echo '  add [user]     Add a new user and password.'
                echo '                 As 2nd parameter you can optionally add a username.'
                echo '                 Without given user it will be asked for interactively.'
                echo '                 If the user exists it will update its password.'
                echo '  delete [user]  Delete a user and all its backup data(!!!).'
                echo '                 Without given user you get the status and it will be asked'
                echo '                 for interactively.'
                ;;
esac

# ------------------------------------------------------------
