#!/bin/sh
# 
# Helper script for managing your Q3A library and starting a map.
#
# IMPORTANT: You may need to edit to suit your setup. 
# Check the lines with:
# "=== Editing may be required ==="
#
# - Tig : https://lvlworld.com/
#

# Where is the main Q3A directory?
# === Editing may be required ===
HOME_Q3A="${HOME}/.q3a"
HOME_DEV="${HOME}/.q3a_dev"

# Engines
# === Editing may be required ===
ENGINE_IOQ3="${HOME}/.ioquake3/ioquake3.x86_64"
ENGINE_Q3E="${HOME}/.quake3e/quake3e.x64"
ENGINE_Q3A="/usr/local/bin/quake3"

# Zip files are stored here. They can be all in one directory or 
# divided into sub-directories. Up to you.
# === Editing may be required ===
HOME_ZIP="${HOME}/.q3a/zip"

# Set the defaults
# === Editing may be required ===
WIDTH="1920"
HEIGHT="1080"
R_FULLSCREEN="1"
R_MODE="-1"
R_PICMAP="0"
R_SUBDIVISIONS="4"
ENGINE=${ENGINE_IOQ3}
HOME_PATH=" +set fs_homepath \"${HOME_Q3A}\""
GAME_PATH=""
MAP=""
MOD=""

# =============================================================
# You are welcome to edit below, but that should not be needed.
# =============================================================

# A version number using yyyymmdd format
VERSION="20250921"
# Use -D to set to DEBUG mode
DEBUG=""

# The zip extract option supports one or many args, so it needs to be handled
# outside of getopts
ZIP_LIST=""
ZIP_APP=""
ZIP_RAW=""
ZIP_WILD=""

# Basic help screen / info
usage () {
	windowMode="Window mode"
	if [ "${R_FULLSCREEN}" != "0" ]
	then
		windowMode="Full screen"
	fi
	zCount=0
	if [ -n "${HOME_ZIP}" -a -d "${HOME_ZIP}" ]
	then
		zCount=$(find /home/tigger/.q3a/zip -type f -name "*.[zZ][iI][pP]" | sed -n '$=')
	fi
	app=${0##*/}
	out="
Start Quake 3, ioquake3 or Quake3e with a map or not, in a mod or not.

Also extracts PK3s from zip files or cleans up your baseq3 directory.

Usage:
 ${app} [map]
 ${app} [-dDqiefw] [-r N] [-s WxH] [-M mod] [map]
 ${app} [-m map] [-zZ zip...]
 ${app} -c | -h | -v

Defaults are:
 - Start ${ENGINE##*/}
 - ${WIDTH}x${HEIGHT} screen size.
 - ${windowMode}
 - r_mode ${R_MODE}
 - No map, but by-pass the intro video.

Engine Options are:
 -q : Quake 3
 -i : ioquake3
 -e : Quake3e

Screen options:
 -f     : Full screen mode.
 -w     : Window screen mode.
 -s WxH : Use a screen size width of \"W\" and height of \"H\".
 -r N   : Change r_mode from ${R_MODE} to \"N\".

Mod support. Can be combined with other options.
 -M mod : Use \"mod\" instead of the base game. \"mod\" is the directory
          of the mod in your baseq3 directory.

PK3 file extraction from zip files:
 -m [map]  : After unzipping, load this map. Must appear before \"-z\"
             or \"-Z\". Without \"-m map\" the script will only extract
             PK3s then exit.
 -z [list] : (lower \"z\") All matches in \"list\" are extracted.
 -Z [list] : (upper \"Z\") Wild card matches are extracted.

\"-z list\" or \"-Z list\" MUST be last on the command line. \"list\" Can be
any number of zip files. The .zip extension is not required. With the
\"-z\" (lower \"z\") option it is possible to include a wildcard as well,
but it must be escaped. See examples for more details.

Misc:
 -c : Remove any custom PK3s and text files from /baseq3
 -d : (For developers) Use a developer directory instead.
 -D : Debug mode. Do not run the commands, show them.
 -h : Show this help and exit. Other options will be ignored.
 -v : Show a summary of options and the script version.

Examples:

Start Q3A with the default game engine and bypass the intro video.

 ${app}

Same as above and start the map \"q3dm13\"

 ${app} q3dm13

Same as above, using the ioquake3 engine (-i), in full screen mode (-f)
with a screen size of 1920 wide by 1080 high (-s 1920x1080). You can 
combine options.

 ${app} -ifs 1920x1080 q3dm13

Same as above with the CPMA mod (-M cpma). The value passed with -M
must be the directory name in baseq3, not the name of the mod.

 ${app} -ifs 1920x1080 -M cpma q3dm13

Same as above and extract the PK3s from the zip files \"cpm1a\" and
\"hub3aeroq3a\" before starting \"q3dm13\". It is important to note that
\"-m q3dm13\" is required when combined with a PK3 extraction if you also 
want to start the game engine. Without \"-m\" the PK3s will be extracted
then the script will exit.

 ${app} -ifs 1920x1080 -M cpma -m q3dm13 -z cpm1a hub3aeroq3a

Using a wildcard (*) with \"-z\" (lower case \"z\") will extract all the
matching files so long as the wildcard is escaped with a \"\\\". This
example will extract all zip files that start with \"tig_\".

 ${app} -z tig_\*

Wildcard PK3 extraction with \"-Z\" (upper case) is a little different
and easier to type. This example will search for zip files that
contains \"dm\" at ANY point in the name and extract it. If you have a
lot of zip files, this may not be the result you really want.

 ${app} -Z dm

Clean up your baseq3 directory by removing any extracted PK3s. The
base game files will be ignored. A confirmation of each deletion is 
required.

 ${app} -c

Game engines:
Quake 3   : ${ENGINE_Q3A}
ioquake3  : ${ENGINE_IOQ3} 
Quake3e   : ${ENGINE_Q3E}

Directories:
Main game : ${HOME_Q3A}
Deveroper : ${HOME_DEV}
Zip files : ${HOME_ZIP}

Number of zip files : ${zCount}
Version: ${VERSION}

"
	printf "%s\n" "${out}"
	exit
}

problem () {
	printf "\n---------------------------\nProblem:\n%s\n\n" "${1}"
	exit 1
}

# Check the defaults and other things on startup
variableCheck () {
	issue=""
	if [ ! -d "${HOME_Q3A}" ]
	then
		issue="${issue}
 - HOME_Q3A set to invalid directory \"${HOME_Q3A}\"
   This will need to be edited to a valid directory."
	elif [ ! -d "${HOME_Q3A}/baseq3" ]
	then
		# Valid base, but missing baseq3?
		issue="${issue}
 - HOME_Q3A is valid, but does not contain a \"baseq3\" directory."
	fi
	if [ -n "${HOME_Q3A}" -a ! -d "${HOME_DEV}" ]
	then
		issue="${issue}
 - HOME_DEV set to invalid directory \"${HOME_DEV}\"
   If you do not have a developer environment, set HOME_DEV to \"\" (blank)."
	fi
	if [ -n "${ENGINE_IOQ3}" -a ! -f "${ENGINE_IOQ3}" ]
	then
		issue="${issue}
 - ENGINE_IOQ3 set to invalid engine path \"${ENGINE_IOQ3}\"
   If you do not have ioquake3 installed, set ENGINE_IOQ3 to \"\" (blank)."
	fi
	if [ -n "${ENGINE_Q3E}" -a ! -f "${ENGINE_Q3E}" ]
	then
		issue="${issue}
 - ENGINE_Q3E set to invalid engine \"${ENGINE_Q3E}\"
   If you do not have Quake3e installed, set ENGINE_Q3E to \"\" (blank)."
	fi
	if [ -n "${ENGINE_Q3A}" -a ! -f "${ENGINE_Q3A}" ]
	then
		issue="${issue}
 - ENGINE_Q3A set to invalid engine \"${ENGINE_Q3A}\"
   If you do not have the Quake 3 engine, set ENGINE_Q3A to \"\" (blank)."
	fi
	if [ -n "${HOME_ZIP}" -a ! -d "${HOME_ZIP}" ]
	then
		issue="${issue}
 - HOME_ZIP set to invalid directory \"${HOME_ZIP}\"
   If you do not have a directory of zip files, set HOME_ZIP to \"\" (blank)."
	elif [ -n "${HOME_ZIP}" -a -d "${HOME_ZIP}" ]
	then
		# We need to make sure unzip is installed. If unzip is missing, this
		# only become a problem when we want to extract files. Save any error
		# message until then.
		ZIP_APP=$(command -v unzip)
	fi
	if [ -z "${issue}" -a ! -f "${ENGINE}" ]
	then
		issue="${issue}
 - ENGINE (default engine) has been set to \"${ENGINE}\"
   This variable will need to edit to a valid file."
	fi
	if [ -n "${issue}" ]
	then
		printf "\nDefault variable issue(s):\n%s\n\nYou will need to edit this script in a text editor to correct any\nissues before going any further.\n\n" "${issue}"
		exit 1
	fi
}

startEngine () {
	# Get the options sorted. Most options do not need to be set on each load,
	# but you could expand this to suit your needs.
	OPTIONS=" +set sv_pure 0 +set r_mode ${R_MODE} +set r_customwidth ${WIDTH} +set r_customheight ${HEIGHT} +set r_fullscreen ${R_FULLSCREEN} +set r_subdivisions ${R_SUBDIVISIONS} +set r_picmip ${R_PICMAP}"

	# Run the game.
	if [ "${DEBUG}" = "yes" ]
	then
		printf "DEBUG:\n%s\n\n" "${ENGINE}${HOME_PATH}${GAME_PATH}${OPTIONS} +map \"${MAP}\""
	else
		#printf "\n[%s]\n\n" "${ENGINE}${HOME_PATH}${GAME_PATH}${OPTIONS} +map \"${MAP}\""
		${ENGINE}${HOME_PATH}${GAME_PATH}${OPTIONS} +map "${MAP}"
	fi
}

# A loop with options
# $1 : The list to loop over
# $2 : The base to filter. eg, ${HOME_Q3A}
utilCleanList () {
	list="${1}"
	fBase="${2}"
	riskEverything="no"
	count=1
	tCount=`printf "%s" "${list}" | sed -n '$='`
	IFS="
"
	if [ "${DEBUG}" = "yes" ]
	then
		for f in ${list}
		do
			printf "[%s of %s] %s\n" "${count}" "${tCount}" "${f##${fBase}}"
			if [ "${riskEverything}" = "yes" ]
			then
				printf "DEBUG: %s\n" "rm -rf \"${f}\""
			else
				printf "[D]elete (default) | [I]gnore | Remove [ALL] | [C]ancel (quit) "
				read ans
				if [ -z "${ans}" -o "${ans}" = "d" -o "${ans}" = "D" ]
				then
					printf "DEBUG: %s\n" "rm -rf \"${f}\""
				elif [ "${ans}" = "i" -o "${ans}" = "I" ]
				then
					printf "Ignoring %s\n\n" "${f##${fBase}}"
				elif [ "${ans}" = "c" -o "${ans}" = "C" -o "${ans}" = "q" -o "${ans}" = "Q" ]
				then
					printf "\nCancelling as requested.\n\n"
					exit
				elif [ "${ans}" = "ALL" ]
				then
					printf "\nWill remove the remaining items from the list without asking.\n\n"
					riskEverything="yes"
					printf "DEBUG: %s\n" "rm -rf \"${f}\""
				else
					printf "\nInvalid response. Ignoring as that is the safest option.\n\n"
				fi
			fi
			count=$((count + 1))
		done
	else
		for f in ${list}
		do
			printf "[%s of %s] %s\n" "${count}" "${tCount}" "${f##${fBase}}"
			if [ "${riskEverything}" = "yes" ]
			then
				rm -rf "${f}"
				printf "Removed %s\n\n" "${f##${fBase}}"
			else
				printf "[D]elete (default) | [I]gnore | Remove [ALL] | [C]ancel (quit) "
				read ans
				if [ -z "${ans}" -o "${ans}" = "d" -o "${ans}" = "D" ]
				then
					rm -rf "${f}"
					printf "Removed %s\n\n" "${f##${fBase}}"
				elif [ "${ans}" = "i" -o "${ans}" = "I" ]
				then
					printf "Ignoring %s\n\n" "${f##${fBase}}"
				elif [ "${ans}" = "c" -o "${ans}" = "C" -o "${ans}" = "q" -o "${ans}" = "Q" ]
				then
					printf "\nCancelling as requested.\n\n"
					exit
				elif [ "${ans}" = "ALL" ]
				then
					printf "\nWill remove the remaining items from the list without asking.\n\n"
					riskEverything="yes"
					rm -rf "${f}"
					printf "Removed %s\n\n" "${f##${fBase}}"
				else
					printf "\nInvalid response. Ignoring as that is the safest option.\n\n"
				fi
			fi
			count=$((count + 1))
		done
	fi
	unset IFS
}

# Checks the main baseq3 directory for none standard pk3's and text
# files and offers an option to remove them.
utilPK3Clean () {
	list=`find "${HOME_Q3A}/baseq3" -maxdepth 1 -type f \( -name "*.[pP][kK]3" -o -name "*.[tT][xX][tT]" -o -name "[rR][eE][aA][dD][-_ ]?[mM][eE]" \) | grep -iv "/pak[0-9].pk3\|/description.txt\|/crashlog.txt" | sort -n`
	if [ -z "${list}" ]
	then
		printf "\nNo extra PK3 files in the base game directory.\n\n"
		exit
	fi
	printf "\nFound the following extra file(s):\n\n"
	utilCleanList "${list}" "${HOME_Q3A}"
	if [ -z "${fullClean}" ]
	then
		printf "\nAll done.\n\n"
		exit
	fi
}

# More like a quick summary of the defaults and the version number.
utilVersion () {
	app=${0##*/}
	zCount=0
	if [ -n "${HOME_ZIP}" -a -d "${HOME_ZIP}" ]
	then
		zCount=$(find /home/tigger/.q3a/zip -type f -name "*.[zZ][iI][pP]" | sed -n '$=')
	fi
	out="
Overview of ${app}

Defaults:
Game engine    : ${ENGINE##*/}
Screen width   : ${WIDTH}
Screen height  : ${HEIGHT}
r_fullscreen   : ${R_FULLSCREEN}
r_picmip       : ${R_PICMAP}
r_subdivisions : ${R_SUBDIVISIONS}

Game engines:
Quake 3        : ${ENGINE_Q3A}
ioquake3       : ${ENGINE_IOQ3} 
Quake3e        : ${ENGINE_Q3E}

Directories:
Main game      : ${HOME_Q3A}
Deveroper      : ${HOME_DEV}
Zip files      : ${HOME_ZIP}

Misc:
Number of zip files : ${zCount}

Script Version : ${VERSION}
"
	printf "%s\n\n" "${out}"
	exit
}

# Try to locate the requested zip file(s) and extract
utilZip () {
	utilZipCheck
	ZIP_RAW=""
	NOT_FOUND=""
	if [ "${ZIP_WILD}" = "yes" ]
	then
		printf "\nLooking for requested zip files (wildcard mode).\n"
		for z in ${ZIP_LIST}
		do
			tmp=$(find "${HOME_ZIP}" -type f -name "*${z}*")
			if [ -n "${tmp}" ]
			then
				ZIP_RAW="${ZIP_RAW}${tmp}
"
			else
				NOT_FOUND="${NOT_FOUND} - ${z}
"
			fi
		done
	else
		printf "\nLooking for requested zip files.\n"
		for z in ${ZIP_LIST}
		do
			printf "%s" "${z}" | grep -qi '\.zip$'
			if [ ${?} -eq 0 ]
			then
				tmp=$(find "${HOME_ZIP}" -type f -name "${z}")
			else
				tmp=$(find "${HOME_ZIP}" -type f -name "${z}.[zZ][iI][pP]")
			fi
			if [ -n "${tmp}" ]
			then
				ZIP_RAW="${ZIP_RAW}${tmp}
"
			else
				NOT_FOUND="${NOT_FOUND} - ${z}
"
			fi
		done
	fi

	# If any of the files were not found
	utilZipNotFound

	# Move to extract
	if [ -n "${ZIP_RAW}" ]
	then
		utilZipExtract
	fi
	
	# We only load Q3A if a map was passed
	if [ -z "${MAP}" ]
	then
		printf "\nAll done.\n\n"
		exit
	fi
}

utilZipCheck () {
	if [ -z "${HOME_ZIP}" -o ! -d "${HOME_ZIP}" ]
	then
		problem "Request to extract a zip file was made, but the HOME_ZIP is not valid.

Was looking for \"${HOME_ZIP}\"

Edit this script and set HOME_ZIP to a valid directory."
	fi
	if [ -z "${ZIP_APP}" ]
	then
		problem "\"unzip\" is required to extract the contents of any zip files (with
this script). You will need to install it first."
	fi
}

utilZipExtract () {
	# Need to know how many files, so we can do a safety check and also to show
	# progress.
	count=1
	tCount=`printf "%s" "${ZIP_RAW}" | sed -n '$='`
	if [ ${tCount} -gt 9 ]
	then
		printf "\nYou have requested to extract the PK3 files from %d zip files.\n\nDoes this seem correct? [Y/n] " ${tCount}
		read ans
		if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
		then
			continue
		elif [ "${ans}" = "n" -o "${ans}" = "N" ]
		then
			printf "\nCancelling as requested.\n\n"
			exit
		else
			printf "\nInvalid response. Cancelling as that is the safest option.\n\n"
			exit
		fi
	fi
	# Finally, extract the files!
	if [ ${tCount} -eq 1 ]
	then
		printf "\nExtracting the contents of a zip file\n\n"
	else
		printf "\nExtracting the contents of %d zip files\n\n" "${tCount}"
	fi
	cd "${HOME_Q3A}/baseq3"
	if [ "${DEBUG}" = "yes" ]
	then
		for z in ${ZIP_RAW}
		do
			printf "DEBUG:\n[%d of %d] %s -j \"%s\"\n" ${count} ${tCount} "${ZIP_APP}" "${z}"
			count=$((count + 1))
		done
	else
		for z in ${ZIP_RAW}
		do
			printf "[%d of %d] %s\n" ${count} ${tCount} "${z##*/}"
			${ZIP_APP} -jq "${z}"
			count=$((count + 1))
		done
	fi
	# All done now
	return
}

utilZipNotFound () {
	if [ -n "${NOT_FOUND}" ]
	then
		printf "\nNo match found for the following:\n\n%s" "${NOT_FOUND}"
		if [ -z "${ZIP_RAW}" ]
		then
			# Nothing to extract, so return
			return
		fi
		printf "\nContinue anyway? [Y/n] "
		read ans
		if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
		then
			continue
		elif [ "${ans}" = "n" -o "${ans}" = "N" ]
		then
			printf "\nCancelling as requested.\n\n"
			exit
		else
			printf "\nInvalid response. Cancelling as that is the safest option.\n\n"
			exit
		fi
	fi
}

# For people that guess stuff. This does mean we can not have a map 
# called either "h" or "help". There is current no map named either
# on ..::LvL so it should be OK.
if [ "${1}" = "h" -o "${1}" = "help" -o "${1}" = "-h" -o "${1}" = "--help" ]
then
	usage
fi

# Do a system check
variableCheck

# Selected options?
while getopts qiehcdDfm:M:r:s:vwzZ o
do	
	case $o in
		q)
			if [ -f "${ENGINE_Q3A}" ]
			then
				ENGINE="${ENGINE_Q3A}"
			fi
			;;
		i)
			if [ -f "${ENGINE_IOQ3}" ]
			then
				ENGINE="${ENGINE_IOQ3}"
			fi
			;;
		e)
			if [ -f "${ENGINE_Q3E}" ]
			then
				ENGINE="${ENGINE_Q3E}"
			fi
			;;
		c)
			utilPK3Clean;;
		d)
			if [ -n "${HOME_DEV}" -a -d "${HOME_DEV}" ]
			then
				HOME_PATH=" +set fs_homepath \"${HOME_DEV}\""
			else
				problem "Developer mode selected but missing a developer directory.

Was looking for \"${HOME_DEV}\"

Edit this script and set HOME_DEV to a valid directory."
			fi
			;;
		D)
			DEBUG="yes";;
		h)
			usage;;
		f)
			R_FULLSCREEN="1";;
		w)
			R_FULLSCREEN="0";;
		s)
			w=${OPTARG%x*}
			h=${OPTARG##*x}
			if [ -n "${w}" -a -n "${h}" ]
			then
				WIDTH=${w}
				HEIGHT=${h}
			else
				usage
			fi
			;;
		r)
			R_MODE=${OPTARG};;
		m)
			MAP=${OPTARG};;
		M)
			MOD=${OPTARG};;
		v)
			utilVersion;;
		z)
			shift $((OPTIND - 1))
			ZIP_LIST=${@};;
		Z)
			shift $((OPTIND - 1))
			ZIP_WILD="yes"
			ZIP_LIST=${@};;
		\?)
			usage;;
	esac
done

# This will make any extra args will be starting at ${1}
shift $((OPTIND - 1))

# Are we extracting zip files?
if [ -n "${ZIP_LIST}" ]
then
	utilZip
fi

# Loading a mod or setting a map?
if [ -n "${MOD}" ]
then
	if [ ! -d "${HOME_Q3A}/${MOD}" ]
	then
		printf "\nRequest to load a \"%s\" as a mod, but unable to locate that directory.\n\nContinue any? [Y/n] " "${MOD}"
		read ans
		if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
		then
			continue
		elif [ "${ans}" = "n" -o "${ans}" = "N" ]
		then
			printf "\nCancelling as requested.\n\n"
			exit
		else
			printf "\nInvalid response. Cancelling as that is the safest option.\n\n"
			exit
		fi
	else
		GAME_PATH=" +set fs_game \"${MOD}\""
	fi
fi
if [ -n "${1}" -a -z "${MAP}" ]
then
	MAP=${1}
fi

# And ...
startEngine

exit

