#!/bin/bash

#####################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################


#####################################################
#
# Simple and dirty script for generating one alert 
# file per pcap by using snort
#
# Author: solacol
# Version: 0.1_20180411
#
#####################################################
#
#
# TODO:
#   - Handle existing/non-existing directories and files
#	- FORK FORK FORK ^^
#	- Using a better way for getting current directory
#
###

# Cmdline argument
ARG=${1}

# Binaries
SNORT="$(/usr/bin/which snort)"
ECHO="$(/usr/bin/which echo)"
TOUCH="$(/usr/bin/which touch)"
RM="$(/usr/bin/which rm)"
MV="$(/usr/bin/which mv)"
PWD="$(/usr/bin/which pwd)"
MKDIR="$(/usr/bin/which mkdir)"
LSOF="$(/usr/bin/which lsof)"
CHOWN="$(/usr/bin/which chown)"
FIND="$(/usr/bin/which find)"

# Direcotries, files
CURRENTDIR="$(${PWD})"
LOCKFILE=${CURRENTDIR}/${ARG}/snort_pcap2alert.lock
STORAGEDIR=${CURRENTDIR}/${ARG}/snort_out
PCAPSRCDIR=${CURRENTDIR}/${ARG}/pcaps
SNORTCONFFILE='/etc/snort/snort.conf'

# If no arg is given, set default directories
if [[ -z ${ARG} ]]; then
        LOCKFILE=${CURRENTDIR}/snortPcap2Alert.lock
        STORAGEDIR=${CURRENTDIR}/snort_out
        PCAPSRCDIR=${CURRENTDIR}/pcaps
fi

# Misc
USER='userXXX'
GROUP='groupXXX'

# Check if script is already running
trap "{ ${RM} -f $LOCKFILE; exit 255; }" EXIT
if  [ -f ${LOCKFILE} ]; then
   ${ECHO} "Script seems to run already?"
else
	# Create lock file
	${TOUCH} $LOCKFILE

	# Process pcap files
	for file in $(${FIND} ${PCAPSRCDIR} -type f -iname "*.pcap[0-9]*" -printf "%f\n"); do
        ${ECHO} "Working with file ${file}"

        workdir=${STORAGEDIR}/${file}
        ${MKDIR} ${workdir}

        openfile="$(${LSOF} ${PCAPSRCDIR}/${file})"

		# Check if some process is working on this pcap file
        if [[ -z ${openfile} ]]; then
            ${SNORT} -q -A full -c ${SNORTCONFFILE} -r ${PCAPSRCDIR}/${file} -l ${workdir}

        	# Check if file size is greater 0
        	if [[ -s ${workdir}/alert ]]; then
                ${RM} -f ${LOCKFILE}
                ${CHOWN} -R ${USER}:${GROUP} ${workdir}
        	else
                ${ECHO} "No alerts for ${file}"
                ${RM} -rf ${workdir}
        	fi
        else
                ${ECHO} "File ${file} seems to be in use? Skipping ..."
        fi
	done
fi

exit 0

