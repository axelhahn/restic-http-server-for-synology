#!/usr/bin/bash
# ======================================================================
#
# INSTALL RESTIC HTTP SERVER ON SYNOLOGY NAS
#
# ----------------------------------------------------------------------
# License: GNU GPL 3.0
# ----------------------------------------------------------------------
# 2021-03-29  www.axelhahn.de  init ... but WIP
# ======================================================================


# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

resticVersion=0.10.0

urlRestic=https://github.com/restic/rest-server/releases/download/v${resticVersion}/rest-server_${resticVersion}_linux_arm64.tar.gz

dlFile=$( basename $urlRestic )
resticDir=rest-server_${resticVersion}_linux_arm64
resticLink=rest-server

resticScript=rest_server.sh
autostart=/usr/local/etc/rc.d/$resticScript

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

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

echo
echo "========== INSTALL RESTIC SERVER =========="
echo
cd $( dirname $0 ) || _quit "cannot change directory ..."

uname -m | grep "arch64" >/dev/null || _quit "Sorry installer is for arch64 Synolgy NAS"


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


_h2 "autostart"
sudo echo "$( pwd )/$resticScript \$*" >$autostart && sudo chmod 755 $autostart \
        || echo "WARNING: unable to create autostart $autostart ... it requires root permissions"
echo "INFO: file $autostart was created ... with content"
cat $autostart



echo
echo
echo "INSTALLATION SUCCESSFUL!"
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
