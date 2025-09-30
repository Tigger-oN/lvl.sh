#!/bin/sh
# 
# Helper script for managing your Q3A library and starting a map.
# - Tig : https://lvlworld.com/
#
# TODO:
# - Possible intergation with ..::LvL
#   + A search option returning basic text details (title, author, release date)
#   + Expand to show map stats (downloads, votes, comment count)
#   + Quick link options to view site

# A version number using yyyymmdd format
VERSION="20250929"

# Localised variables. Use -S (setup) to update or edit manually in a text
# editor.
LVL_RC="${HOME}/.lvl.sh.rc"
LVL_APP="${0##*/}"

HOME_PATH=""
GAME_PATH=""
MAP=""
MOD=""
# If dev mode is requested, we need to change the HOME_PATH
DEV=""
# If a PK3 clean is requested.
PK3_CLEAN=""

# Use -D to set to DEBUG mode
DEBUG=""
# Use -S to run set-up. Will also be required if LVL_RC is missing.
SETUP_REQUIRED=""

# The PK3 extract option supports one or many args, so it needs to be handled
# outside of getopts
ZIP_LIST=""
ZIP_APP=""
ZIP_RAW=""
ZIP_WILD=""

# Horizontal bar or rule - nothing more.
HR="---------------------------------------------------------------------"

# Header
LVL_HEADER="
    @@@#.                                        .#@@@.
  :: -@@@@*.                                    .+@@@@- :-
  *@@##@@@@@+                                  +@@@@@##@@#
   *@@@@@@@@@@-                              -%@@@@@@@@@*
 ###%@@@@@@@@@@#            -%%-            #@@@@@@@@@@%###.
 +@@@@@@@@@@@@@@:       .=#@@@@@@#=.       .@@@@@@@@@@@@@@+
  =@@@@@@@@@@@@@.     :#@@@@@@@@@@@@%:      @@@@@@@@@@@@@+.
 *@@@@@@@@@@@@@@      =@@@@@@@@@@@@@@+      %@@@@@@@@@@@@@#
  -@@@@@@@@@@@@+       .--%@@@@@@%--:       +@@@@@@@@@@@@-
  %@@@@@@@@@@@@*          @@@@@@@@          +@@@@@@@@@@@@%.
  .=*@@@@@@@@@@@          .      .          %@@@@@@@@@@#=.
   .@@@@@@@@@@@@=      :=+##%@@%%#*=:      -@@@@@@@@@@@@.
    #%@@@@@@@@@@@-  =#@@@@@@@@@@@@@@@@%=. :@@@@@@@@@@@%#.
      %@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@%
      =@@@@@@%=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=%@@@@@@+
       :-%@@@. .*@@@@@@@@@@@@@@@@@@@@@@@@@@*.  @@@%-:
        :+@@@:   =@@@@@@@@@@@@@@@@@@@@@@@@=   .@@@*-
       .@@@@@@#*: %@@@@@@@@@@@@@@@@@@@@@@@ :+#@@@@@@:
         #@@@@@@* @@@@@@@@@@@@@@@@@@@@@@@@ =@@@@@@#
          +%@@@* :@%-    .:%@@@@%-.    -%@- +@@@%+.
            @@=  *@.       :@@@@-       .@#  -@@.
          -%%:   @@-      .#@@@@#.      :@@   .#%-
        =%#-    +@@@#+=+*%@@*..*@@%*+=+#@@@+    :*%+
        .      .@@@@@%**=@@+    +@@=**%@@@@@:      .
                .*%@@@@@%@@+  . =@@%@@@@@%#:
                       .@@@@@@@@@@@@:
                        @@@@@@@@@@@@
                        -%@@@@@@@@%-
"

# Basic help screen / info
usage () {
	# Because the rc file could be missing.
	engine="${ENGINE:=Q3A}"
	width="${WIDTH:=1024}"
	height="${HEIGHT:=768}"
	fullscreen="${R_FULLSCREEN:=1}"

	windowMode="Window mode"
	if [ "${fullscreen}" != "0" ]
	then
		windowMode="Full screen"
	fi
	zCount=0
	if [ -n "${HOME_ZIP}" -a -d "${HOME_ZIP}" ]
	then
		zCount="$(find "${HOME_ZIP}" -type f -name "*.[zZ][iI][pP]" | sed -n '$=')"
	fi

	out="
Start Quake 3, ioquake3 or Quake3e with a map or not, in a mod or not.

Also extracts PK3s from zip files or cleans up your baseq3 directory.

Usage:
 ${LVL_APP} [map]
 ${LVL_APP} [-dDqiefSw] [-s WxH] [-M mod] [map]
 ${LVL_APP} [-m map] [-zZ zip...]
 ${LVL_APP} -c | -h | -v

Defaults are:
 - Start ${engine##*/}
 - ${width}x${height} screen size.
 - ${windowMode}
 - No map, but by-pass the intro video.

Engine options are:
 -q : Quake 3
 -i : ioquake3
 -e : Quake3e

Screen options:
 -f     : Full screen mode.
 -w     : Window screen mode.
 -s WxH : Use a screen size width of \"W\" and height of \"H\".

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
 -S : (Upper case S) Run the setup process to set variables.
 -v : Show a summary of options and the script version, then exit.

Examples:

Start Q3A with the default game engine and bypass the intro video.

 ${LVL_APP}

Same as above and start the map \"q3dm13\"

 ${LVL_APP} q3dm13

Same as above, using the ioquake3 engine (-i), in full screen mode (-f)
with a screen size of 1920 wide by 1080 high (-s 1920x1080). You can 
combine options.

 ${LVL_APP} -ifs 1920x1080 q3dm13

Same as above with the CPMA mod (-M cpma). The value passed with -M
must be the directory name in baseq3, not the name of the mod.

 ${LVL_APP} -ifs 1920x1080 -M cpma q3dm13

Same as above and extract the PK3s from the zip files \"cpm1a\" and
\"hub3aeroq3a\" before starting \"q3dm13\". It is important to note that
\"-m q3dm13\" is required when combined with a PK3 extraction if you also 
want to start the game engine. Without \"-m\" the PK3s will be extracted
then the script will exit.

 ${LVL_APP} -ifs 1920x1080 -M cpma -m q3dm13 -z cpm1a hub3aeroq3a

Using a wildcard (*) with \"-z\" (lower case \"z\") will extract all the
matching files so long as the wildcard is escaped with a \"\\\". This
example will extract all zip files that start with \"tig_\".

 ${LVL_APP} -z tig_\*

Wildcard PK3 extraction with \"-Z\" (upper case) is a little different
and easier to type. This example will search for zip files that
contains \"dm\" at ANY point in the name and extract it. If you have a
lot of zip files, this may not be the result you really want.

 ${LVL_APP} -Z dm

Clean up your baseq3 directory by removing any extracted PK3s. The
base game files will be ignored. A confirmation of each deletion is 
required.

 ${LVL_APP} -c

Game engines:
Quake 3   : ${ENGINE_Q3A:-Unconfirmed}
ioquake3  : ${ENGINE_IOQ3:-Unconfirmed} 
Quake3e   : ${ENGINE_Q3E:-Unconfirmed}

Directories:
Main game : ${HOME_Q3A:-Unconfirmed}
Deveroper : ${HOME_DEV:-Unconfirmed}
Zip files : ${HOME_ZIP:-Unconfirmed}

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

# Check if a var is a number.
isNumber () {
	case "${1}" in
		''|*[!0-9]*) IS_NUMBER="";;
		*) IS_NUMBER="yes";;
	esac
}

# Check the defaults and other things on startup
variableCheck () {
	issue=""
	if [ ! -d "${HOME_Q3A}" ]
	then
		issue="${issue}
 - HOME_Q3A set to an invalid directory:
   \"${HOME_Q3A}\"
   This will need to be edited to a valid directory."
	elif [ ! -d "${HOME_Q3A}/baseq3" ]
	then
		# Valid base, but missing baseq3?
		issue="${issue}
 - HOME_Q3A is valid, but does not contain a \"baseq3\" directory."
	fi
	if [ -n "${HOME_DEV}" -a ! -d "${HOME_DEV}" ]
	then
		issue="${issue}
 - HOME_DEV set to an invalid directory:
   \"${HOME_DEV}\"
   If you do not have a developer environment, set HOME_DEV to \"\" (blank)."
	fi
	if [ -n "${ENGINE_IOQ3}" -a ! -f "${ENGINE_IOQ3}" ]
	then
		issue="${issue}
 - ENGINE_IOQ3 set to an invalid engine path:
   \"${ENGINE_IOQ3}\"
   If you do not have ioquake3 installed, set ENGINE_IOQ3 to \"\" (blank)."
	fi
	if [ -n "${ENGINE_Q3E}" -a ! -f "${ENGINE_Q3E}" ]
	then
		issue="${issue}
 - ENGINE_Q3E set to in nvalid engine path:
   \"${ENGINE_Q3E}\"
   If you do not have Quake3e installed, set ENGINE_Q3E to \"\" (blank)."
	fi
	if [ -n "${ENGINE_Q3A}" -a ! -f "${ENGINE_Q3A}" ]
	then
		issue="${issue}
 - ENGINE_Q3A set to an invalid engine path:
   \"${ENGINE_Q3A}\"
   If you do not have the Quake 3 engine, set ENGINE_Q3A to \"\" (blank)."
	fi
	if [ -n "${HOME_ZIP}" -a ! -d "${HOME_ZIP}" ]
	then
		issue="${issue}
 - HOME_ZIP set to an invalid directory:
   \"${HOME_ZIP}\"
   If you do not have a directory of zip files, set HOME_ZIP to \"\" (blank)."
	elif [ -n "${HOME_ZIP}" -a -d "${HOME_ZIP}" ]
	then
		# We need to make sure unzip is installed. If unzip is missing, this
		# only becomes a problem when we want to extract files. Save any error
		# message until then.
		ZIP_APP="$(command -v unzip)"
	fi
	if [ -z "${issue}" -a ! -f "${ENGINE}" ]
	then
		issue="${issue}
 - ENGINE (default engine) has been set to an invalid option:
   \"${ENGINE}\"
   This variable will need to be set to a valid file."
	fi
	if [ -n "${issue}" ]
	then
		printf "\nDefault variable issue(s):\n%s\n\nYou will need to run the setup (%s -S) or edit your \"%s\" in a text\neditor before going any further.\n\n" "${issue}" "${LVL_APP}" "${LVL_RC##*/}"
		printf "Do you want to run the setup process now? [Y/n] "
		read ans
		if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
		then
			setup
		else
			exit 1
		fi
	fi
}

startEngine () {
	# Get the options sorted. Most options do not need to be set on each load,
	# but you could expand this to suit your needs.

	# Check for some required variables as it is possible to reach here (with
	# some effort) without having a valid setup.
	issue=""
	if [ -z "${ENGINE}" -o ! -f "${ENGINE}" ]
	then
		issue="${issue} - ENGINE is not valid or missing.
"
	fi
	if [ "${HOME_PATH}" = " +set fs_homepath \"\"" ]
	then
		issue="${issue} - Issue with the HOME_PATH. This would be related to HOME_Q3A or
   HOME_DEV
"
	fi
	if [ -n "${issue}" ]
	then
		problem "${issue}"
	fi

	# Should be OK to continue
	OPTIONS=" +set sv_pure 0 +set r_mode ${R_MODE} +set r_customwidth ${WIDTH} +set r_customheight ${HEIGHT} +set r_fullscreen ${R_FULLSCREEN} +set r_subdivisions ${R_SUBDIVISIONS} +set r_picmip ${R_PICMAP}"

	# Run the game.
	if [ "${DEBUG}" = "yes" ]
	then
		printf "DEBUG:\n%s\n\n" "${ENGINE}${HOME_PATH}${GAME_PATH}${OPTIONS} +map \"${MAP}\""
	else
		${ENGINE}${HOME_PATH}${GAME_PATH}${OPTIONS} +map "${MAP}"
	fi
}

# A loop with options
# $1 : The base to filter. eg, ${HOME_Q3A}
# $2 : The list to loop over
utilCleanList () {
	fBase="${1}"
	list="${2}"
	riskEverything="no"
	count=1
	tCount="$(printf "%s" "${list}" | sed -n '$=')"
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
			count="$((count + 1))"
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
			count="$((count + 1))"
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
		printf "\nNo extra PK3 files in the base game directory.\n"
	else
		printf "\nFound the following extra file(s):\n\n"
		utilCleanList "${HOME_Q3A}" "${list}"
	fi
	printf "\nPK3 clean done.\n\n[P]rocess any other options and start Q3A (default) or [E]xit "
	read ans
	if [ "${ans}" = "e" -o "${ans}" = "E" ]
	then
		printf "\nExiting as requested.\n\n"
		exit
	fi
}

# More like a quick summary of the defaults and the version number.
utilVersion () {
	zCount=0
	if [ -n "${HOME_ZIP}" -a -d "${HOME_ZIP}" ]
	then
		zCount="$(find "${HOME_ZIP}" -type f -name "*.[zZ][iI][pP]" | sed -n '$=')"
	fi
	out="
Overview of ${LVL_APP}

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
Run command file    : ${LVL_RC}

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
			tmp="$(find "${HOME_ZIP}" -type f -name "*${z}*")"
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
				tmp="$(find "${HOME_ZIP}" -type f -name "${z}")"
			else
				tmp="$(find "${HOME_ZIP}" -type f -name "${z}.[zZ][iI][pP]")"
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
		problem "Request to extract a zip file was made but the HOME_ZIP is not valid.

Was looking for: \"${HOME_ZIP}\"

Run setup (${LVL_APP} -S) or edit \"${LVL_RC##*/}\" and set HOME_ZIP to a
valid directory."
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
	tCount="$(printf "%s" "${ZIP_RAW}" | sed -n '$=')"
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
			count="$((count + 1))"
		done
	else
		for z in ${ZIP_RAW}
		do
			printf "[%d of %d] %s\n" ${count} ${tCount} "${z##*/}"
			${ZIP_APP} -jq "${z}"
			count="$((count + 1))"
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

# When there is more than one option, present a list and allow for custom
# option too.
# SETUP_LIST  The list of options. One per line.
# SETUP_VAR   The selected option will be set to this.
setupMoreThanOne () {
	SETUP_VAR=""
	printf "\nMore than one possible result.\n\n"
	count=1
	IFS="
"
	for r in ${SETUP_LIST}
	do
		printf " %d) %s\n" ${count} "${r}"
		count=$((count + 1))
	done
	unset IFS
	printf "\n%s\nUse [number] | <enter> to skip | [A]dd your own | [C]ancel " "${HR}"
	read ans
	if [ -z "${ans}" ]
	then
		# Skipping
		return
	elif [ "${ans}" = "c" -o "${ans}" = "C" -o "${ans}" = "q" -o "${ans}" = "Q" ]
	then
		printf "\nCancelling as requested.\n\n"
		exit
	elif [ "${ans}" = "a" -o "${ans}" = "A" ]
	then
		# Adding their own
		printf "\nWhat is the correct path? Copy and paste recommended, there is no tab\ncompletion.\n\n "
		read ans
		if [ -f "${ans}" -o -d "${ans}" ]
		then
			printf "\nUsing: %s\n" "${ans}"
			SETUP_VAR="${ans}"
		else
			printf "\nThat result appears to be invalid. Assuming you know what you are doing.\nYou can run the setup again later or edit \"%s\" manually.\n" "${LVL_RC##*/}"
			SETUP_VAR="${ans}"
		fi
	else
		# Checking for a valid option.
		isNumber ${ans}
		if [ "${IS_NUMBER}" = "yes" ]
		then
			# Which option was that?
			count=1
			IFS="
"
			for r in ${SETUP_LIST}
			do
				if [ ${count} -eq ${ans} ]
				then
					SETUP_VAR="${r}"
					unset IFS
					return
				fi
				count="$((count + 1))"
			done
			unset IFS
		fi
		printf "\nThat was not a valid option. Try again\n"
		setupMoreThanOne
	fi
}

# The majority of the setup checks are identical except for a few key points.
# SETUP_VAR   will be set to either "" or a path to a file or directory.
# SETUP_DESC  needs to be set to a description of what you are looking for.
setupVarCheckExisting () {
	printf "\n\nLooking for your %s.\n" "${SETUP_DESC}"
	if [ -n "${SETUP_VAR}" ]
	then
		if [ -f "${SETUP_VAR}" -o -d "${SETUP_VAR}" ]
		then
			printf "\nCurrently set to:\n\n %s\n\nKeep using this one? [Y/n] " "${SETUP_VAR}"
		else
			printf "\nCurrently invalid and set to:\n\n %s\n\nKeep the invalid value? [Y/n] " "${SETUP_VAR}"
		fi
		read ans
		if [ "${ans}" = "n" -o "${ans}" = "N" ]
		then
			printf "\nResetting %s.\n" "${SETUP_DESC}"
			SETUP_VAR=""
		else
			printf "\nWill continue to use:\n\n %s\n" "${SETUP_VAR}"
		fi
	fi
}

# SETUP_DESC  A description of what you are looking for.
# SETUP_LIST  Can be one or many lines of options. Can NOT be blank.
# SETUP_VAR   What the result is.
setupVarCheck () {
	count=$(printf "%s" "${SETUP_LIST}" | sed -n '$=')
	autoPick=""
	if [ ${count} -eq 1 ]
	then
		SETUP_VAR="$(printf "%s" "${SETUP_LIST}" | tr -d '\n')"
		autoPick="(auto-discovered) "
	else
		# More than one result. Need to work out which is correct.
		setupMoreThanOne
	fi
	if [ -n "${SETUP_VAR}" ]
	then
		printf "\n%s%s set to:\n\n %s\n" "${autoPick}" "${SETUP_DESC}" "${SETUP_VAR}"
	else
		printf "\n%s will be skipped.\n" "${SETUP_DESC}"
	fi
}

# Need to know if locate is installed, which version and if the DB is updated.
# setup will fail to run without locate or a locate.db
# FreeBSD uses locate.database and does not support -b
# MacOS uses mdfind
# This is for Linux only
setupLocateCheck () {
	printf "\nChecking \"locate\" is installed.\n"
	tmp=$(command -v locate)
	if [ -z "${tmp}" ]
	then
		# No locate, need to switch to manual mode.
		setupManual
		return
	fi
	lastIndex=""
	# Check for the plocate version
	if [ -n "$(command -v plocate)" ]
	then
		# Check for a plocate.db and when it was last updated
		tmp="$(locate -ib plocate.db | grep '/plocate.db$')"
		if [ -n "${tmp}" ]
		then
			lastIndex="$(stat --format="%y" "${tmp}" | cut -d'.' -f1)"
		fi
	elif [ -n "$(command -v mlocate)" ]
	then
		tmp="$(locate -ib mlocate.db | grep '/mlocate.db$')"
		if [ -n "${tmp}" ]
		then
			lastIndex="$(stat --format="%y" "${tmp}" | cut -d'.' -f1)"
		fi
	elif [ -n "$(command -v slocate)" ]
	then
		tmp="$(locate -ib slocate.db | grep '/slocate.db$')"
		if [ -n "${tmp}" ]
		then
			lastIndex="$(stat --format="%y" "${tmp}" | cut -d'.' -f1)"
		fi
	else
		# Old school!
		# This version of locate is not supported and very old on Linux.
		# Need to shift to manual mode
		setupManual
		return
	fi

	if [ -n "${lastIndex}" ]
	then
		printf "\nThe locate database was last updated %s.\n\nAnything installed after this date may not be found.\n\nYou can run \"sudo updatedb\" (which could take some time) to force a\nfresh index if needed.\n" "${lastIndex}"
	else
		printf "\nYou have \"locate\" installed but the locate database is missing or has\nnot been updated yet. You can run \"sudo updatedb\" (which could take\nsome time) to force an update now, then run this script again.\n\n"
		exit 1
	fi
}

# Manual setup.
# Write out a blank rc file if missing.
# Offer to edit it now.
setupManual () {
	if [ ! -f "${LVL_RC}" ]
	then
		printf "\n%s is currently missing. Writing a blank.\n" "${LVL_RC##*/}"
		out="# ${LVL_APP} run command file. Edit to taste.
# ${HR}
# If you run \"${LVL_APP} -S\" this file will be overwritten.
# ${HR}

# Main Quake 3 Arena directory:
HOME_Q3A=\"${HOME_Q3A}\"

# Deveroper Quake 3 Arena directory (optional):
HOME_DEV=\"${HOME_DEV}\"

# Zip file directory for PK3 extraction (optional):
HOME_ZIP=\"${HOME_ZIP}\"

# Path to default game engine:
ENGINE=\"${ENGINE}\"

# Path to Quake 3 Arena applicaiton (optional):
ENGINE_Q3A=\"${ENGINE_Q3A}\"

# Path to ioquake3 applicaiton (optional):
ENGINE_IOQ3=\"${ENGINE_IOQ3}\"

# Path to Quake3e applicaiton (optional):
ENGINE_Q3E=\"${ENGINE_Q3E}\"

# Use a screen width and height of:
WIDTH="${WIDTH}"
HEIGHT="${HEIGHT}"

# Run Q3A in fullscreen mode (1=yes, 0=Window mode):
R_FULLSCREEN=\"${R_FULLSCREEN}\"

# Render textures sharp (0) or blurry (16):
R_PICMAP=\"${R_PICMAP}\"

# Make curves (pathces) smooth (0 or 1) or lumpy (16):
R_SUBDIVISIONS=\"${R_SUBDIVISIONS}\"

# Not part of the setup, but required because we set a custom width
# and height.
R_MODE=\"-1\"
"
		printf "%s" "${out}" > "${LVL_RC}"
	fi
	# Check for an editor
	editCmd=""
	if [ -n "${VISUAL}" ]
	then
		editCmd="${VISUAL}"
	elif [ -n "${EDITOR}" ]
	then
		editCmd="${EDITOR}"
	else
		# Check for a system default
		editCmd=$(command -v "${DEFAULT_EDITOR}")
		if [ -z "${editCmd}" ]
		then
			editCmd=$(command -v vim)
		fi
		if [ -z "${editCmd}" ]
		then
			editCmd=$(command -v nano)
		fi
		if [ -z "${editCmd}" ]
		then
			editCmd=$(command -v vi)
		fi
	fi
	# Only open if we have an editor.
	if [ -z "${editCmd}" ]
	then
		printf "\nUnable to automatically detect a common text editor. You will need to\nmanually open and edit the run command file:\n\n %s\n\n... then start again.\n\n" "${LVL_RC}"
		exit 1
	fi
	# Offer the choice to edit now (and continue) or later (and exit).
	printf "\nWould you like to edit the \"%s\" now? [Y/n] " "${LVL_RC##*/}"
	read ans
	if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
	then
		${editCmd} "${LVL_RC}"
		# And pull in the rc file as there could have been changes.
		. "${LVL_RC}"
	else
		printf "\nOpen \"%s\" in any text editor to make changes to suit your\nsetup and needs. The full path is:\n\n %s\n\n" "${LVL_RC##*/}" "${LVL_RC}"
		exit
	fi
}

# Set and reset some common variables needed.
# This entire setup function relies on \"locate\" to be up to date and
# installed! It is possible to have a Linux distro without locate :(
setup () {
	printf "\nStarting the setup process.\n"
	# setup relies on locate, which is different on Linux to FreeBSD to MacOS
	if [ "$(uname)" = "Linux" ]
	then
		# Only Linux is supported at the moment. Will anyone else ever use this?
		setupLocateCheck
	else
		setupManual
		return
	fi
	# Start the checks
	printf "\nWill try to locate and set the common variables. Confirmation may be\nrequired.\n"
	# Keep track of the game engines. Used with setting a default later.
	ENGINE_COUNT=0
	ENGINE_LIST=""
	# Check for main baseq3 directory
	SETUP_VAR="${HOME_Q3A}"
	SETUP_DESC="main Quake 3 Arena directory"
	setupVarCheckExisting
	HOME_Q3A="${SETUP_VAR}"
	if [ -z "${HOME_Q3A}" ]
	then
		# Can not used shell expansion as case is unknown
		SETUP_LIST="$(locate -i "/baseq3/pak0.pk3" | sed 's#/baseq3/pak0.pk3##ig')"
		if [ -z "${SETUP_LIST}" ]
		then
			printf "\n - Unable to locate your main Quake 3 Arena directory. This could\n   happen if your setup is new and your directories have not been\n   indexed yet with \"locate\". You can edit \"%s\" or re-run\n   setup later.\n" "${LVL_RC##*/}"
		else
			SETUP_DESC="Main Quake 3 Arena directory"
			setupVarCheck 
			HOME_Q3A="${SETUP_VAR}"
		fi
	fi
	# Check for developer directory. Would not be common and could be called anything!
	SETUP_VAR="${HOME_DEV}"
	SETUP_DESC="Q3A developer directory"
	setupVarCheckExisting
	HOME_DEV="${SETUP_VAR}"
	if [ -z "${HOME_DEV}" ]
	then
		SETUP_LIST="$(locate -i "/baseq3/scripts/shaderlist.txt" | sed 's#/baseq3/scripts/shaderlist.txt##ig')"
		if [ -z "${SETUP_LIST}" ]
		then
			printf "\n - Unable to locate a possible Q3A developer directory. This is 100%%\n   optional and can be skipped. If you do have a developer directory\n   you can edit \"%s\" or re-run setup later.\n" "${LVL_RC##*/}"
		else
			SETUP_DESC="Q3A developer directory"
			setupVarCheck
			HOME_DEV="${SETUP_VAR}"
		fi
	fi
	# Game engines
	SETUP_VAR="${ENGINE_Q3A}"
	SETUP_DESC="main Quake 3 Arena application"
	setupVarCheckExisting
	ENGINE_Q3A="${SETUP_VAR}"
	if [ -z "${ENGINE_Q3A}" ]
	then
		# Quake 3 binary should be in the path, but would be called "quake3"
		# and will more than like be a mess to locate the real app. Still,
		# check for it.
		SETUP_LIST="$(command -v quake3.x86)"
		if [ -z "${SETUP_LIST}" ]
		then
			# Oh well, no real surprise :(
			SETUP_LIST="$(locate -i /quake3.x86 | grep -i '/quake3.x86$' | xargs -r -I {} sh -c '[ -f "{}" ] && echo "{}"')"
		fi
		if [ -z "${SETUP_LIST}" ]
		then
			printf "\n - Unable to locate a possible Quake 3 Arena application. It is\n   possible to use an alternative Q3A engine and will assume this is\n   what you have. If you do have the official release you can edit\n   \"%s\" or re-run setup later.\n" "${LVL_RC##*/}"
		else
			SETUP_DESC="Main Quake 3 Arena application"
			setupVarCheck
			ENGINE_Q3A="${SETUP_VAR}"
		fi
	fi
	if [ -n "${ENGINE_Q3A}" ]
	then
		ENGINE_COUNT=$((ENGINE_COUNT + 1))
		ENGINE_LIST="${ENGINE_LIST}${ENGINE_Q3A}
"
	fi
	SETUP_VAR="${ENGINE_IOQ3}"
	SETUP_DESC="ioquake3 application"
	setupVarCheckExisting
	ENGINE_IOQ3="${SETUP_VAR}"
	if [ -z "${ENGINE_IOQ3}" ]
	then
		# ioquake3 binary could be in the path
		SETUP_LIST="$(command -v ioquake3.x86_64)"
		if [ -z "${SETUP_LIST}" ]
		then
			# Oh well :(
			SETUP_LIST="$(locate -ib ioquake3.x86_64 | xargs -r -I {} sh -c '[ -f "{}" ] && echo "{}"')"
		fi
		if [ -z "${SETUP_LIST}" ]
		then
			printf "\n - Unable to locate a possible ioquake3 application. Was looking for\n   \"ioquake3.x86_64\"\n   If you do have ioquake3 installed you can edit \"%s\" or\n   re-run setup later.\n" "${LVL_RC##*/}"
		else
			SETUP_DESC="ioquake3 application"
			setupVarCheck
			ENGINE_IOQ3="${SETUP_VAR}"
		fi
	fi
	if [ -n "${ENGINE_IOQ3}" ]
	then
		ENGINE_COUNT=$((ENGINE_COUNT + 1))
		ENGINE_LIST="${ENGINE_LIST}${ENGINE_IOQ3}
"
	fi
	SETUP_VAR="${ENGINE_Q3E}"
	SETUP_DESC="Quake3e application"
	setupVarCheckExisting
	ENGINE_Q3E="${SETUP_VAR}"
	if [ -z "${ENGINE_Q3E}" ]
	then
		# Quake3e binary comes in two version and we have no idea which is being used :(
		SETUP_LIST="$(locate -ib quake3e.x64 | xargs -r -I {} sh -c '[ -f "{}" ] && echo "{}"')"
		tmp="$(locate -ib quake3e-vulkan.x64 | xargs -r -I {} sh -c '[ -f "{}" ] && echo "{}"')"
		if [ -n "${tmp}" ]
		then
			SETUP_LIST="${SETUP_LIST}
${tmp}"
		fi
		if [ -z "${SETUP_LIST}" ]
		then
			printf "\n - Unable to locate a possible Quake3e application. Was looking for\n   \"quake3e.x64\" and \"quake3e-vulkan.x64\"\n   If you do have Quake3e installed you can edit \"%s\" or\n   re-run setup later.\n\n" "${LVL_RC##*/}"
		else
			SETUP_DESC="Quake3e application"
			setupVarCheck
			ENGINE_Q3E="${SETUP_VAR}"
		fi
	fi
	if [ -n "${ENGINE_Q3E}" ]
	then
		ENGINE_COUNT=$((ENGINE_COUNT + 1))
		ENGINE_LIST="${ENGINE_LIST}${ENGINE_Q3E}
"
	fi
	# Ah. something impossible to check for :(
	SETUP_VAR="${HOME_ZIP}"
	SETUP_DESC="zip file directory"
	setupVarCheckExisting
	HOME_ZIP="${SETUP_VAR}"
	if [ -z "${HOME_ZIP}" ]
	then
		printf "\n${LVL_APP} can unzip PK3 files from a zip file, but it needs to know where\nthose zip files are.\n\nTo use PK3 extraction:\n - add the base directory for the zip files\n - or, enter the file name of a zip in that directory\n - or, leave blank to skip.\n\n "
		read ans
		if [ -z "${ans}" ]
		then
			HOME_ZIP=""
			printf "\nSkipping PK3 extraction from zip files. You can always add this later.\n"
		elif [ -d "${ans}" ]
		then
			HOME_ZIP="${ans}"
			printf "\nZip directory confirmed. Adding PK3 extraction support.\n"
		else
			# Check for a possible zip file
			printf "\nChecking...\n"
			SETUP_LIST="$(locate -i "${ans}" | grep -i '.zip$' | sed 's#/[^/]*$##ig')"
			if [ -z "${SETUP_LIST}" ]
			then
				printf "\n - Unable to confirm the location a zip file or directory. You will\n   need to edit \"%s\" or re-run setup later.\n" "${LVL_RC##*/}"
			else
				SETUP_DESC="Zip file directory"
				setupVarCheck
				HOME_ZIP="${SETUP_VAR}"
			fi
		fi
	fi
	# Personal options
	printf "\n\nPersonal default values:\n"
	# Default game engine
	SETUP_VAR="${ENGINE}"
	SETUP_DESC="default game engine"
	SETUP_LIST="${ENGINE_LIST}"
	setupVarCheckExisting
	ENGINE="${SETUP_VAR}"
	if [ -z "${ENGINE}" -a -n "${ENGINE_LIST}" ]
	then
		SETUP_DESC="Default game engine"
		setupVarCheck
		ENGINE="${SETUP_VAR}"
	fi
	# Fullscreen or window mode?
	printf "\n"
	if [ -n "${R_FULLSCREEN}" ]
	then
		if [ "${R_FULLSCREEN}" = "1" ]
		then
			printf "\nCurrently set to run in fullscreen mode. Keep this? [Y/n] "
		elif [ "${R_FULLSCREEN}" = "0" ]
		then
			printf "\nCurrently set to run in window mode. Keep this? [Y/n] "
		else
			printf "\nThe variable \"R_FULLSCREEN\" should be either \"1\" for fullscreen mode\nor \"0\" for window mode. Currently this is set to:\n\n %s\n\nDo you want to keep this? [Y/n] " "${R_FULLSCREEN}"
		fi
		read ans
		if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
		then
			printf "\nNo changes made.\n"
		elif [ "${ans}" = "n" -o "${ans}" = "N" ]
		then
			R_FULLSCREEN=""
			printf "\nCleared.\n"
		else
			printf "\nInvalid response. No changes made as that is the safest option.\n"
		fi
	fi
	if [ -z "${R_FULLSCREEN}" ]
	then
		printf "\nRun Q3A in [F]ullscreen (default) or [W]indow mode? "
		read ans
		if [ -z "${ans}" -o "${ans}" = "f" -o "${ans}" = "F" ]
		then
			printf "\nWill run in fullscreen mode.\n"
			R_FULLSCREEN="1"
		elif [ "${ans}" = "w" -o "${ans}" = "W" ]
		then
			printf "\nWill run in window mode.\n"
			R_FULLSCREEN="0"
		else
			printf "\nNot a valid option, defaulting to fullscreen mode.\n"
			R_FULLSCREEN="1"
		fi
	fi
	# Width and height
	printf "\n"
	if [ -n "${WIDTH}" -a -n "${HEIGHT}" ]
	then
		printf "\nDisplay size is set to \"%s\" (width) by \"%s\" (height). Keep this? [Y/n] " "${WIDTH}" "${HEIGHT}"
		read ans
		if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
		then
			printf "\nNo changes made.\n"
		elif [ "${ans}" = "n" -o "${ans}" = "N" ]
		then
			printf "\nCleared.\n"
			WIDTH=""
			HEIGHT=""
		else
			printf "\nInvalid response. No changes made as that is the safest option.\n"
		fi
	fi
	if [ -z "${WIDTH}" -o -z "${HEIGHT}" ]
	then
		if [ -n "$(command -v xrandr)" ]
		then
			# X Server
			wxh="$(xrandr 2>/dev/null | grep -m1 '*' | awk '{print $1}')"
		fi
		if [ -n "${wxh}" ]
		then
			w="${wxh%x*}"
			h="${wxh##*x}"
			printf "\nFound a fullscreen size of \"%s\" (width) by \"%s\" (height).\n\nWould you like to run Q3A at this screen size? [Y/n] " "${w}" "${h}"
			read ans
			if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
			then
				WIDTH="${w}"
				HEIGHT="${h}"
				printf "\nSetting a display size of \"%s\" (width) by \"%s\" (height).\n" "${WIDTH}" "${HEIGHT}"
			fi
		fi
	fi
	if [ -z "${WIDTH}" -o -z "${HEIGHT}" ]
	then
		printf "\nSetting the display screen size to run Quake 3 Arena at.\n\nWhat width to use? "
		read ans
		isNumber ${ans}
		if [ "${IS_NUMBER}" = "yes" ]
		then
			WIDTH="${ans}"
		else
			printf "\nOnly numbers can be used for the screen width. Try again: "
			read ans
			isNumber ${ans}
			if [ "${IS_NUMBER}" = "yes" ]
			then
				WIDTH="${ans}"
			else
				printf "\nStill invalid. Setting to a width of 1024.\n"
				WIDTH="1024"
			fi
		fi
		printf "\nWhat screen height would like to use? "
		read ans
		isNumber ${ans}
		if [ "${IS_NUMBER}" = "yes" ]
		then
			HEIGHT="${ans}"
		else
			printf "\nOnly numbers can be used for the screen height. Try again: "
			read ans
			isNumber ${ans}
			if [ "${IS_NUMBER}" = "yes" ]
			then
				HEIGHT="${ans}"
			else
				printf "\nStill invalid. Setting to a height of 768.\n"
				HEIGHT="768"
			fi
		fi
		printf "\nSetting a display size of \"%s\" (width) by \"%s\" (height).\n" "${WIDTH}" "${HEIGHT}"
	fi
	# R_PICMAP : 0 to 16
	printf "\n"
	if [ -n "${R_PICMAP}" ]
	then
		invalid=" (invalid)"
		isNumber ${R_PICMAP}
		if [ "${IS_NUMBER}" = "yes" ]
		then
			invalid=""
		fi
		printf "\nTexture softness (R_PICMAP) is currently set to \"%s\"%s.\n\nValid ranges are from 0 (sharp) to 16 (solid blur). Keep this? [Y/n] " "${R_PICMAP}" "${invalid}"
		read ans
		if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
		then
			printf "\nNo changes made.\n"
		elif [ "${ans}" = "n" -o "${ans}" = "N" ]
		then
			printf "\nCleared.\n"
			R_PICMAP=""
		else
			printf "\nInvalid response. No changes made as that is the safest option.\n"
		fi
	fi
	if [ -z "${R_PICMAP}" ]
	then
		printf "\nSet a texture softness (R_PICMAP) from 0 (sharp) to 16 (solid blur).\n\nDefault Quake 3 Arena value was 1. For today's graphic cards 0 is\ntotally fine and is the default if left blank. [0-16] "
		read ans
		isNumber "${ans}"
		if [ -z "${ans}" ]
		then
			R_PICMAP=0
		elif [ "${IS_NUMBER}" = "yes" -a ${ans} -ge 0 -a ${ans} -le 16 ]
		then
			R_PICMAP="${ans}"
		else
			printf "\nInvalid range. Setting to \"0\"\n"
			R_PICMAP=0
		fi
		printf "\nTexture softness (R_PICMAP) set to \"%s\"\n" "${R_PICMAP}"
	fi
	# R_SUBDIVISIONS : 0 to 16
	printf "\n"
	if [ -n "${R_SUBDIVISIONS}" ]
	then
		invalid=" (invalid)"
		isNumber ${R_SUBDIVISIONS}
		if [ "${IS_NUMBER}" = "yes" ]
		then
			invalid=""
		fi
		printf "\nPatch density for curves (R_SUBDIVISIONS) is currently set to \"%s\"%s.\n\nValid ranges are from 0 (smooth circle) to 16 (obvious divisions, like\nan octagon). Keep this? [Y/n] " "${R_SUBDIVISIONS}" "${invalid}"
		read ans
		if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
		then
			printf "\nNo changes made.\n"
		elif [ "${ans}" = "n" -o "${ans}" = "N" ]
		then
			printf "\nCleared.\n"
			R_SUBDIVISIONS=""
		else
			printf "\nInvalid response. No changes made as that is the safest option.\n"
		fi
	fi
	if [ -z "${R_SUBDIVISIONS}" ]
	then
		printf "\nSet a patch density for curves (R_SUBDIVISIONS) from 0 (smooth circle)\nto 16 (obvious divisions, like an octagon).\n\nDefault Quake 3 Arena value was 4. For today's graphic cards 0 or 1 is\ntotally fine. The default if left blank is 1. [0-16] "
		read ans
		isNumber "${ans}"
		if [ -z "${ans}" ]
		then
			R_SUBDIVISIONS=1
		elif [ "${IS_NUMBER}" = "yes" -a ${ans} -ge 0 -a ${ans} -le 16 ]
		then
			R_SUBDIVISIONS="${ans}"
		else
			printf "\nInvalid range. Setting to \"1\"\n"
			R_SUBDIVISIONS=1
		fi
		printf "\nPatch density for curves (R_SUBDIVISIONS) set to \"%s\"\n" "${R_SUBDIVISIONS}"
	fi
	# We have everything we need at the moment.
	# Review, then save
	out="
${HR}
Selected variables are:
 - Main Quake 3 Arena directory:
   HOME_Q3A=\"${HOME_Q3A}\"

 - Deveroper Quake 3 Arena directory (optional):
   HOME_DEV=\"${HOME_DEV}\"

 - Zip file directory for PK3 extraction (optional):
   HOME_ZIP=\"${HOME_ZIP}\"

 - Default game engine:
   ENGINE=\"${ENGINE}\"

 - Quake 3 Arena applicaiton (optional):
   ENGINE_Q3A=\"${ENGINE_Q3A}\"

 - ioquake3 applicaiton (optional):
   ENGINE_IOQ3=\"${ENGINE_IOQ3}\"

 - Quake3e applicaiton (optional):
   ENGINE_Q3E=\"${ENGINE_Q3E}\"

 - Use a screen width and height of:
   WIDTH="${WIDTH}"
   HEIGHT="${HEIGHT}"

 - Run Q3A in fullscreen mode (1=yes, 0=Window mode):
   R_FULLSCREEN=\"${R_FULLSCREEN}\"

 - Render textures sharp (0) or blurry (16):
   R_PICMAP=\"${R_PICMAP}\"

 - Make curves (patches) smooth (0 or 1) or lumpy (16):
   R_SUBDIVISIONS=\"${R_SUBDIVISIONS}\"

Save options your \"${LVL_RC##*/}\"? [Y/n] "
 
	printf "%s" "${out}"
	read ans
	if [ -z "${ans}" -o "${ans}" = "y" -o "${ans}" = "Y" ]
	then
		# Save to rc
		out="# ${LVL_APP} run command file. Edit to taste.
# ${HR}
# If you run \"${LVL_APP} -S\" this file will be overwritten.
# ${HR}

# Main Quake 3 Arena directory:
HOME_Q3A=\"${HOME_Q3A}\"

# Deveroper Quake 3 Arena directory (optional):
HOME_DEV=\"${HOME_DEV}\"

# Zip file directory for PK3 extraction (optional):
HOME_ZIP=\"${HOME_ZIP}\"

# Default game engine:
ENGINE=\"${ENGINE}\"

# Quake 3 Arena applicaiton (optional):
ENGINE_Q3A=\"${ENGINE_Q3A}\"

# ioquake3 applicaiton (optional):
ENGINE_IOQ3=\"${ENGINE_IOQ3}\"

# Quake3e applicaiton (optional):
ENGINE_Q3E=\"${ENGINE_Q3E}\"

# Use a screen width and height of:
WIDTH="${WIDTH}"
HEIGHT="${HEIGHT}"

# Run Q3A in fullscreen mode (1=yes, 0=Window mode):
R_FULLSCREEN=\"${R_FULLSCREEN}\"

# Render textures sharp (0) or blurry (16):
R_PICMAP=\"${R_PICMAP}\"

# Make curves (pathces) smooth (0 or 1) or lumpy (16):
R_SUBDIVISIONS=\"${R_SUBDIVISIONS}\"

# Not part of the setup, but required because we set a custom width
# and height.
R_MODE=\"-1\"

"
		if [ "${DEBUG}" = "yes" ]
		then
			printf "\nDEBUG: Would have written the following to:\n \"%s\"\n\n%s" "${LVL_RC}" "${out}"
		else
			printf "%s" "${out}" > "${LVL_RC}"
		fi
		printf "\nSetup is done!\n\nIf you like you can make changes to the \"%s\" at anytime using a\ntext editor. The file is located here:\n\n %s\n\nAll done.\n\n" "${LVL_RC##*/}" "${LVL_RC}"

	else
		printf "\nDo you want to [R]edo the setup or [C]ancel (default)? "
		read ans
		if [ "${ans}" = "r" -o "${ans}" = "R" ]
		then
			setup
			return
		else
			printf "\nCancelling as requested.\n\n"
			exit
		fi
	fi
}

# Check for an existing rc
if [ -f "${LVL_RC}" ]
then
	# Pull it in
	. "${LVL_RC}"
else
	# It's missing!
	SETUP_REQUIRED="yes"
fi

# For people that guess stuff. This does mean we can not have a map 
# called either "h" or "help". There is current no map named either
# on ..::LvL so it should be OK.
if [ "${1}" = "h" -o "${1}" = "help" -o "${1}" = "-h" -o "${1}" = "--help" ]
then
	usage
fi

# Selected options?
while getopts qiehcdDfm:M:s:SvwzZ o
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
			PK3_CLEAN="yes";;
		d)
			DEV="yes";;
		D)
			DEBUG="yes";;
		h)
			usage;;
		f)
			R_FULLSCREEN="1";;
		w)
			R_FULLSCREEN="0";;
		s)
			w="${OPTARG%x*}"
			h="${OPTARG##*x}"
			if [ -n "${w}" -a -n "${h}" ]
			then
				WIDTH="${w}"
				HEIGHT="${h}"
			else
				usage
			fi
			;;
		S)
			SETUP_REQUIRED="yes";;
		m)
			MAP="${OPTARG}";;
		M)
			MOD="${OPTARG}";;
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

# With a PK3 extraction, we only start Q3A if -m is passed.
if [ -n "${1}" -a -z "${MAP}" -a -z "${ZIP_LIST}" ]
then
	MAP="${1}"
fi

# Display the header
printf "%s\n" "${LVL_HEADER}"

# Setup (if required) must be run before anything below this point.
if [ "${SETUP_REQUIRED}" = "yes" ]
then
	setup
fi

# Do a system check
variableCheck

# If cleaning up, do it sooner than later.
if [ "${PK3_CLEAN}" = "yes" ]
then
	utilPK3Clean
fi

# This needs to be set after setup
HOME_PATH=" +set fs_homepath \"${HOME_Q3A}\""

# But do they want the dev environment?
if [ "${DEV}" = "yes" ]
then
	if [ -n "${HOME_DEV}" -a -d "${HOME_DEV}" ]
	then
		HOME_PATH=" +set fs_homepath \"${HOME_DEV}\""
	else
		problem "Developer mode selected but missing a developer directory.

Was looking for \"${HOME_DEV}\"

Run setup or set HOME_DEV to a valid directory in \"${LVL_RC##*/}\"."
	fi
fi

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
		printf "\nRequest to load the mod \"%s\", but unable to locate that directory.\n\nContinue any? [Y/n] " "${MOD}"
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

# And ...
startEngine

exit

