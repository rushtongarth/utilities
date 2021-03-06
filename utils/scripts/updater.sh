#!/bin/bash

thisscript=$(readlink -f $0)
you=`whoami`
LOGDIR=$(dirname $(dirname $thisscript))/logs
OUTLOG=$LOGDIR/$(date +update.%Y%m%d.%H%M%S.log)


if [[ $you != 'root' ]]
then
	printf "you must be root to execute this script\n"
	exit 1
fi
function timestamp
{
	stamp="[$(date +%Y%m%d.%H%M%S)]"
	if [[ -n $1 ]]
	then
		printf "%s %s\n" "$stamp" "$@"
	fi
}
function dircheck
{
	local create=0
	test -d $LOGDIR || create=1
	if [[ $create -eq 1 ]]
	then
		printf "No such directory %s, creating...\n" "$LOGDIR"
		mkdir $LOGDIR
		chown ${SUDO_USER}: $LOGDIR
		timestamp "Created $LOGDIR" >> $OUTLOG
	else
		timestamp "Found $LOGDIR" >> $OUTLOG
	fi
}
function doupdate
{
	local sv=$1
	timestamp "Performing update step" >> $OUTLOG
	apt-get update >> $OUTLOG
	sv=$(( sv+10 ))
	printf "%s\n" "$sv"
	timestamp "Updates complete, starting install" >> $OUTLOG
	apt-get -y dist-upgrade >> $OUTLOG
	sv=$(( sv+10 ))
	printf "%s\n" "$sv"
	timestamp "Install complete" >> $OUTLOG
}
function output
{
	local l1 l2
	l1=$(grep -n 'Updates complete' $OUTLOG | cut -d: -f1)
	l2=`tail -n +$l1 $OUTLOG | grep '^[[:space:]]'`
	if [[ ${#l2} -gt 0 ]]
	then
		printf "The following were updated\n" 1>&2
		printf "%s\n" $l2 1>&2
	else
		printf "Nothing to update\n" 1>&2
	fi
}
function updateclean
{
	local sv=$1
	timestamp "Starting clean up" >> $OUTLOG
	apt-get -y autoremove >> $OUTLOG
	sv=$(( sv+10 ))
	printf "%s\n" "$sv"
	apt-get autoclean >> $OUTLOG
	sv=$(( sv+10 ))
	printf "%s\n" "$sv"
	timestamp "Update complete" >> $OUTLOG
}
function cleandir
{
	indir=$(ls -1tr $LOGDIR)
	c=$(echo "$indir" | wc -l)
	if [[ $c -ge 3 ]]
	then
		timestamp "Found $c old files, removing" >> $OUTLOG
		torm=$(ls -1tr $LOGDIR | head -n-2)
		for i in $torm
		do
			gone=$(rm -v $LOGDIR/$i)
			timestamp "$gone" >> $OUTLOG
		done
	fi
	chown ${SUDO_USER}: $OUTLOG
}

if [[ $# -ne 1 ]]
then
	printf "Please provide one of the following:\n"
	printf "\tfull:\n"
	printf "\t\tCheck directories, update system and clean logs\n"
	printf "\tfast:\n"
	printf "\t\tOnly perform update\n"
	printf "\tclean:\n"
	printf "\t\tremove installed files that are no longer needed\n"
	printf "\t\tclean up the logging directory\n"
fi
## MAIN
{
if [[ $1 == 'full' ]]
then
	dircheck
	printf "10\n"
	timestamp "Full mode selected" >> $OUTLOG
	doupdate 10
	printf "40\n"
	updateclean 40
	printf "75\n"
	cleandir
	printf "100\n"
	output
elif [[ $1 == 'fast' ]]
then
	timestamp "Fast mode selected" >> $OUTLOG
	doupdate 50
	cleandir
	printf "100\n"
	output
elif [[ $1 == 'clean' ]]
then
	timestamp "clean mode selected" >> $OUTLOG
	updateclean 40
	printf "100\n"
	cleandir
fi
} | whiptail --gauge "Performing updates, Thanks for your patience..." 6 80 0
#whiptail --title "Updating..." --textbox /dev/stdin 40 80 <<<"$(tail $OUTLOG)"
