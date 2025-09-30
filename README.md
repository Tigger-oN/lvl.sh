# lvl.sh

Start Quake 3, ioquake3 or Quake3e with a map or not, in a mod or not.

Also extracts PK3s from zip files or cleans up your baseq3 directory.

Usage:

    lvl.sh [map]
    lvl.sh [-dDqiefSw] [-s WxH] [-M mod] [map]
    lvl.sh [-m map] [-zZ zip...]
    lvl.sh -c | -h | -v

Engine Options are:

    -q : Quake 3
    -i : ioquake3
    -e : Quake3e

Screen options:

    -f     : Full screen mode.
    -w     : Window screen mode.
    -s WxH : Use a screen size width of "W" and height of "H".

Mod support. Can be combined with other options.

    -M mod : Use "mod" instead of the base game. "mod" is the directory
             of the mod in your baseq3 directory.

PK3 file extraction from zip files:

    -m [map]  : After unzipping, load this map. Must appear before "-z"
                or "-Z". Without "-m map" the script will only extract
                PK3s then exit.
    -z [list] : (lower "z") All matches in "list" are extracted.
    -Z [list] : (upper "Z") Wild card matches are extracted.

`"-z list"` or `"-Z list"` MUST be last on the command line. "list" Can be
any number of zip files. The .zip extension is not required. With the
`"-z"` (lower "z") option it is possible to include a wildcard as well,
but it must be escaped. See examples for more details.

Misc:

    -c : Remove any custom PK3s and text files from /baseq3
    -d : (For developers) Use a developer directory instead.
    -D : Debug mode. Do not run the commands, show them.
    -h : Show this help and exit. Other options will be ignored.
    -S : (Upper case S) Run the setup process to set variables.
    -v : Show a summary of options and the script version.

Examples:

Start Q3A with the default game engine and bypass the intro video.

    lvl.sh

Same as above and start the map "q3dm13"

    lvl.sh q3dm13

Same as above, using the ioquake3 engine (-i), in full screen mode (-f)
with a screen size of 1920 wide by 1080 high (-s 1920x1080). You can 
combine options.

    lvl.sh -ifs 1920x1080 q3dm13

Same as above with the CPMA mod (-M cpma). The value passed with -M
must be the directory name in baseq3, not the name of the mod.

    lvl.sh -ifs 1920x1080 -M cpma q3dm13

Same as above and extract the PK3s from the zip files "cpm1a" and
"hub3aeroq3a" before starting "q3dm13". It is important to note that
"-m q3dm13" is required when combined with a PK3 extraction if you also 
want to start the game engine. Without "-m" the PK3s will be extracted
then the script will exit.

    lvl.sh -ifs 1920x1080 -M cpma -m q3dm13 -z cpm1a hub3aeroq3a

Using a wildcard (\*) with "-z" (lower case "z") will extract all the
matching files so long as the wildcard is escaped with a "\\". The
example below will extract all zip files that start with "tig_".

    lvl.sh -z tig_\*

Wildcard PK3 extraction with "-Z" (upper case) is a little different
and easier to type. This example will search for zip files that
contains "dm" at ANY point in the name and extract it. If you have a
lot of zip files, this may not be the result you really want.

    lvl.sh -Z dm

Clean up your baseq3 directory by removing any extracted PK3s. The
base game files will be ignored. A confirmation of each deletion is 
required.

    lvl.sh -c


