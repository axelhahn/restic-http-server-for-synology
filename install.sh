#!/usr/bin/bash
# ======================================================================
#
# INSTALL RESTIC HTTP SERVER ON SYNOLOGY NAS
#
# ----------------------------------------------------------------------
# License: GNU GPL 3.0
# ----------------------------------------------------------------------
# 2021-03-29  www.axelhahn.de  init ... but WIP
# 2021-03-31  www.axelhahn.de  create logrotate.d
# ======================================================================


# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

# TODO
# autodetect latest arm linux version
# wget -O aa.tmp https://github.com/restic/rest-server/releases/
# cat aa.tmp | grep "rest-server_.*_linux_arm64.tar.gz"

urlResticReleases=https://github.com/restic/rest-server/releases/
# static variant:
# resticVersion=0.10.0

resticLink=rest-server

resticScript=rest_server.sh
autostart=/usr/local/etc/rc.d/$resticScript
logrotation=/etc/logrotate.d/restic_server

#auth='backup:backup'


# ------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------

function _quit(){
        echo CRITICAL ERROR: $*
        exit 1
}

function _h2(){
        echo
        echo "--- $*"
}

function _getLocalVersion(){
        # test -x $resticLink/rest_server && $resticLink/rest_server -V | cut -f 2 -d ' '
        $resticLink/rest-server -V 2>/dev/null | cut -f 2 -d ' '
        # ls -1 | grep "rest-server_[0-9].*_" | cut -f 2 -d '_' | sort -n | tail -1
}

function _getRemoteVersion(){
        wget -O - $urlResticReleases 2>/dev/null | grep "href.*rest-server_.*_linux_arm64.tar.gz" | cut -f 2 -d '_'
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

echo
echo "========== INSTALL RESTIC SERVER =========="
echo
cd $( dirname $0 ) || _quit "cannot change directory ..."

uname -m | grep "arch64" >/dev/null || _quit "Sorry installer is for arch64 Synolgy NAS"

localversion=$( _getLocalVersion )
echo local version : $localversion
echo -n 'remote version: '
resticVersion=$( _getRemoteVersion )
echo $resticVersion

test -z "$resticVersion" && _quit "Unable to detect remote version from $urlResticReleases"

test "$remoteVersion" = "$localversion" && echo "equal"
urlRestic=https://github.com/restic/rest-server/releases/download/v${resticVersion}/rest-server_${resticVersion}_linux_arm64.tar.gz
dlFile=$( basename $urlRestic )
resticDir=rest-server_${resticVersion}_linux_arm64


_h2 "Download"
if [ -f $dlFile ]; then
        echo "SKIP download"
else
        wget -O ${dlFile}.running -S $urlRestic \
                && mv ${dlFile}.running ${dlFile}
fi
test -f $dlFile || _quit "Download failed."



_h2 "Extract"
tar -xzf ${dlFile} || _quit "Extraction failed."
ls -ld $resticDir || _quit "Extraction was done ... but expected dir $resticDir does not exist. I am confused :-/"



_h2 "Create Link"
rm -f $resticLink || true
ln -s $resticDir $resticLink && ls -l $resticLink || _quit "Unable to create softlink $resticLink."



_h2 "Init dirs"
test -d log  || mkdir log  || _quit "unable to create dir [log]."
test -d data || mkdir data || _quit "unable to create dir [data]."
ls -ld log data


#
# removed after writing useradmin.sh
#
# _h2 "Init default user and password $auth"
# test -f data/.htpasswd && echo "SKIP: data/.htpasswd already exists"
# test -f data/.htpasswd || echo "creating default $auth (unencrypted)" \
#       && echo $auth >data/.htpasswd \
#       || _quit "Unable to create default user and password"


_h2 "Create config"
test -f "$( pwd )/rest_server.conf" && echo "SKIP: rest_server.conf already exists"
test -f "$( pwd )/rest_server.conf" || cp "$( pwd )/rest_server.conf.dist" "$( pwd )/rest_server.conf"
ls -l "$( pwd )/rest_server.conf" || _quit "Unable to create rest_server.conf (copy of .dist file)"
. "$( pwd )/rest_server.conf"


_h2 "Enable autostart"
sudo echo "$( pwd )/$resticScript \$*" >$autostart && sudo chmod 755 $autostart \
        || echo "WARNING: unable to create autostart $autostart ... it requires root permissions"
echo "INFO: file $autostart was created ... with content"
cat $autostart


_h2 'Add logrotation'
cat << EOLOG >$logrotation
$(pwd )/$logfile {
  rotate 7
  daily
  compress
  dateext
  dateformat __%Y-%m-%d

  # firstaction
  #   $autostart stop
  # endscript

  sharedscripts

  postrotate
    $autostart restart
  endscript
}
EOLOG
ls -l $logrotation || _quit "unable to create logrotation file"
# cat /etc/logrotate.d/restic_server


echo
echo
echo "========== INSTALLATION SUCCESSFUL! =========="
echo
echo "(1)"
echo "Have look to rest_server.conf"
echo
echo "(2)"
echo "Create a user to access a private repo with useradmin.sh add [user]"
echo
echo "(3)"
echo "Then start the server with ./rest_server.sh start."

# ------------------------------------------------------------
