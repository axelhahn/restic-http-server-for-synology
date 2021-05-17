#!/usr/bin/bash
# ======================================================================
#
# RESTIC HTTP SERVER ON SYNOLOGY NAS
#
# ----------------------------------------------------------------------
# License: GNU GPL 3.0
# ----------------------------------------------------------------------
# 2021-03-29  www.axelhahn.de  init ... but WIP
# 2021-04-02  www.axelhahn.de  added logrotation
# 2021-05-17  www.axelhahn.de  rename function logrotation
# ======================================================================

#defaults
typeset -i appendonly=0
typeset -i privaterepos=1
typeset -i noauth=0

typeset -i pwlength=32
PRODUCT='RESTIC REST SERVER'



# ----------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------


function UNUSEDcheck_config(){
        local typeset -i iErrors=0
        test -f mydir/rest_server.conf
}

function check_running_server(){
        ps -ef | grep $mybin | grep -v grep | grep .
}

function _addlog(){
        echo "---------- `date` $*" >>$logfile
}

function status(){
        echo
        echo "$PRODUCT STATUS:"
        echo
        echo Binary: $mybin
        $mybin -V
        echo
        echo --- process:
        check_running_server
        if [ $? -ne 0 ]; then
                echo "NOT running"
        else
                echo
                echo --- netstat
                netstat -tulpen | grep $listen
        fi
        echo
}


function start(){

        check_running_server >/dev/null
        if [ $? -eq 0 ]; then
                echo "ERROR: $PRODUCT is running already. Abort."
                exit 1
        fi

        local param_tls=''
        local param_append=''
        local param_noauth=''
        local param_private_repos=''

        test -f $dir_cert/fullchain.pem -a -f $dir_cert/privkey.pem \
                && param_tls="--tls --tls-cert $dir_cert/fullchain.pem --tls-key $dir_cert/privkey.pem"
        test -z "$param_tls" && echo "WARNING: certificate in NAS was not enabled - using unencrypted connection"

        test ${appendonly} -gt 0   && param_append='--append-only'
        test ${noauth} -gt 0       && param_noauth='--no-auth'
        test ${privaterepos} -gt 0 && param_private_repos='--private-repos'

        _addlog "start $PRODUCT"
        nohup $mybin \
            --debug \
                --listen $listen \
                --path $dir_data \
            $param_append \
            $param_noauth \
            $param_private_repos \
                $param_tls \
                >> $logfile &

        # status
        sleep 1
        check_running_server >/dev/null
        if [ $? -eq 0 ]; then
                test -z "$param_tls" && echo "No Certificate - use [http] in your restic client"
                test -z "$param_tls" || echo "Encryption ON - use [https] in your restic client"
                echo "$PRODUCT was started."
        else
                echo --- last lines of log:
                ls -l $logfile
                tail -10 $logfile
                echo
                echo "ERROR: Startup of $PRODUCT failed. See log message above."
                exit 1
        fi
}

function stop(){
        check_running_server >/dev/null
        if [ $? -eq 0 ]; then
                _addlog "stop $PRODUCT"
                echo -n "Stopping $PRODUCT ... "
                killall "$( basename $mybin )"
                check_running_server >/dev/null
                if [ $? -eq 0 ]; then
                        echo "FAILED"
                        exit 1
                else
                        echo "OK"
                fi
        else
                echo "ERROR: $PRODUCT is not running."
                exit 1
        fi
}

function restart(){
        check_running_server >/dev/null
        if [ $? -eq 0 ]; then
                stop
        else
                echo "SKIP: won't stop service ... $PRODUCT is not running"
        fi
        start
}

function do_logrotate(){
        local logrotation=$( grep -l $logfile /etc/logrotate.d/* | head -1 )
        if [ ! -z "$logrotation" ]; then
                echo "INFO: logrotation config $logrotation was detected"
                echo "The daily logrotation will be done by system logrotate service."
                echo "Executing logrotate -v -f $logrotation ..."
                logrotate -v -f $logrotation
                exit $?
        fi

        local rotLog=$logfile.$( date +%Y-%m-%d )
        local keep=7
        ls $rotLog* >/dev/null 2>&1
        if [ $? -eq 0 ]; then
                echo 'SKIP: rotation was already done today'
        else
                echo 'Starting logrotation...'
                ( stop )
                mv $logfile $rotLog
                ( start )
        fi
        echo 'Cleanup old logs ...'
        find $( dirname $logfile ) -type f -name "$( basename $logfile).*" -mtime +$keep -print -delete
        echo 'Logfiles left:'
        ls -l $logfile.*
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

cd `dirname $0`
. rest_server.conf
mybin=$dir_server/rest-server


case "$1" in
        start) start ;;
        stop) stop ;;
        restart) restart ;;
        status) status ;;
        logrotate) do_logrotate ;;
        *)
                echo "USAGE: `basename $0` [start|stop|status|restart|logrotate]"
                ;;
esac

# ------------------------------------------------------------
