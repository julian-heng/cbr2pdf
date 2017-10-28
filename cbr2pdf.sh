#!/bin/bash

preRun () {
	# Pre-converting checks, ensure that there is no missing dependencies

	if [[ $HELP = true ]]; then
		message 14
		exit 1
	fi

	start=$(date +%s)
	START_TIME=$(date +"%T %D")

	if [[ $VERBOSE = true ]]; then
		message 1
	fi

	progList=("7z" "basename" "convert" "date" "dirname" "find" "mkdir" "mv" "rm" "rmdir" "sed" "tput" "unzip")
	checkArg "$OUTPUT_PATH"

	for i in "${progList[@]}"; do
		checkProg "$i"
	done

	if [[ $quit == true ]]; then

		message 12
		exit 1

	fi
	if [[ $VERBOSE = true ]]; then
		message 2
		linebreak
	fi
}

checkArg () {
	# This function checks the arguments and see if they are directories or not
	# If they are not, it will print the usage message and exit

	if [[ ! -d $1 ]]; then

		message 14
		message 13
		exit 1

	fi
}

checkProg () {
	# Check if the program exist, if not then it will state that it is not installed
	# and exit the script.
	
	# If p7z is not installed, the script will fallback to unzip instead. However,
	# due to how some comic archives are compressed, unzip might not be able to 
	# extract those files, thus why p7z is used

	commandName=$1
	commandPath=$(command -v "$commandName")

	if [[ -z $commandPath ]]; then

		message 8
		quit=true

		case $commandName in
			7z)
				message 9
				checkProg unzip
				useUnzip=true
				quit=false
			;;
			convert)
				message 10
		esac

	else

		if [[ $VERBOSE = true ]]; then
			message 11
		fi
	fi
}

linebreak () {
	# Create line breaks according to the size of the terminal

	if [[ $VERBOSE = true ]]; then
		if (( $(tput cols) >= 96)) ; then
			printf "\n"; eval printf '%.0s-' {1..92}; printf "\n"; printf "\n"
		else
			printf "\n"; eval printf '%.0s-' '{1..'"${COLUMNS:-$(tput cols)}"\}; printf "\n"; printf "\n"
		fi
	fi
}

main() {

	TOTAL=$(find "${INPUT_PATH}" -type f | wc -l| sed -e 's/ //g')
	COUNT=1

	while read -r inputFile; do

		PRT_DIR=$(dirname "${INPUT_PATH}")		# Get parent directory in order to remove unecessary long filenames in the variable DST_DIR
		SRC_DIR=${inputFile%/*}					# Get the source directory
		SRC_FILE=${inputFile##*/}				# Get the source file
		SRC_FILENAME=$(basename "$inputFile")	# Get the source filename
		SRC_FILENAME=${SRC_FILENAME%.*}			
		SRC_EXT=${inputFile##*.}				# Get the source file extension
		DST_DIR=${SRC_DIR#$PRT_DIR}				# Get destination directory
		DST_DIR=$OUTPUT_PATH/${DST_DIR#/}

		# Make the destination folder
		mkdir -p "${DST_DIR}"
		
		# Detects the file type and skip if it's not a comic book archive
		if [[ $SRC_EXT == "cbr" ]] || [[ $SRC_EXT == "cbz" ]]; then
			
			# Print file and directory information
			message 3
			printf "\n"

			# Make output directory
			mkdir -p "${DST_DIR}/${SRC_FILENAME}"
			
			# Extract, check, convert and delete
			
			extract "${inputFile}" "${DST_DIR}/${SRC_FILENAME}"
			checkFolder "${DST_DIR}/${SRC_FILENAME}"
			if [[ $EXTRACT != true ]]; then
				convertFile "${DST_DIR}/${SRC_FILENAME}/*.{jpg,png}" "${DST_DIR}/${SRC_FILENAME}.pdf"
				delete "${DST_DIR}/${SRC_FILENAME}"
			fi
			
			message 6
			if [[ $VERBOSE = true ]]; then
				linebreak
			else
				if (( $(tput cols) >= 96)); then
					printf "\n"; eval printf '%.0s-' {1..92}; printf "\n"; printf "\n"
				else
					printf "\n"; eval printf '%.0s-' '{1..'"${COLUMNS:-$(tput cols)}"\}; printf "\n"; printf "\n"
				fi
			fi

		else

			printf "\n"
			message 3
			message 5

		fi
		((++COUNT))
	done < <(find "${INPUT_PATH}" -type f)

	end=$(date +%s)
	END_TIME=$(date +"%T %D")
	progTime=$((end - start))
	message 7
}

extract () {
	# Extracts files

	message 4 1
	linebreak

	if [[ $useUnzip = true ]]; then
		if [[ $VERBOSE = true ]]; then
			unzip "$1" -d "$2"
		else
			unzip "$1" -q -d "$2"; spinner
		fi
	else
		if [[ $VERBOSE = true ]]; then
			7z x "$1" -o"$2"
		else
			7z x "$1" -o"$2" &> /dev/null; spinner
		fi
		
	fi
}

convertFile () {
	# Convert .jpg to .pdf

	message 4 2
	linebreak
	if [[ $VERBOSE = true ]]; then
		convert "$1" -density 100 -verbose "$2"
	else
		convert "$1" -density 100 "$2" &
		spinner
	fi
}

checkFolder () {
	# Sometimes, the images are within a folder after extraction
	# This detects if there is a subfolder after extraction and
	# moves the files up one level

	check=$(find "$1" -type d -maxdepth 2 | sed -n '2 p')

	if [[ $check == "" ]]; then
		message 4 3
		linebreak
	else
		message 4 4
		linebreak
		if [[ $VERBOSE = true ]]; then
			mv -v "$check"/* "$1"
		else
			mv "$check"/* "$1"
		fi
		rmdir "$check"
	fi

	check=""

}

delete () {
	# Delete the extracted files

	message 4 5
	linebreak
	if [[ $VERBOSE = true ]]; then
		rm -rfv "$1"
	else
		rm -rf "$1"
	fi
}

spinner() {
	# Referenced from http://fitnr.com/showing-a-bash-spinner.html
	# By Louis Marascio

	local pid=$!
	local delay=0.1
	local spinstr='|/-\'
	while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
		local temp=${spinstr#?}
		printf " [%c]  " "$spinstr"
		local spinstr=$temp${spinstr%"$temp"}
		sleep $delay
		printf "\b\b\b\b\b\b"
	done
	printf "    \b\b\b\b"

}

message () {
	# Prints out a message the matches the argument after being called


case $1 in
	1)
		message="
${green}Verbose Output${reset}: 	${VERBOSE}
${green}Extract Only${reset}:		${EXTRACT}
${green}Input DIR${reset}: 		${INPUT_PATH}
${green}Output DIR${reset}: 		${OUTPUT_PATH}
${green}Start time${reset}: 		${START_TIME}
\n"
	;;
	2)
		message="
${green}[Info]${reset} 	Complete pre-run checks
${green}[Info]${reset} 	Starting conversion process
"
	;;
	3)
		message="
${green}[Info]${reset} File information:

${green}Job Number${reset}:		${COUNT}/${TOTAL}
${green}Parent Directory${reset}: 	${PRT_DIR}
${green}Source Directory${reset}: 	${SRC_DIR}
${green}Source File${reset}: 		${inputFile}
${green}File Type${reset}: 		${SRC_EXT}
${green}Destination Directory${reset}: 	${DST_DIR}
"
	;;
	4)
	case $2 in
		1)	message="${green}[Info]${reset} Extracting archive...";;
		2)	message="\n${green}[Info]${reset} Converting to PDF...";;
		3)	message="\n${green}[Info]${reset} No subfolders detected...";;
		4)	message="\n${green}[Info]${reset} Subfolders detected, moving...";;
		5)	message="\n${green}[Info]${reset} Deleting extracted files...";;
		*)	
	esac
	;;
	5)	message="${yellow}[Warning]${reset} Not a compatible file. Skipping...\n\n";;
	6)	message="\n\n${green}[Info]${reset} Finish converting ${DST_DIR}/${SRC_FILE}";;
	7)

if [[ $VERBOSE = true ]]; then

	message=\
"${green}[Info]${reset} Finish converting all files
${green}[Info]${reset} Start time is ${START_TIME}
${green}[Info]${reset} End time is ${END_TIME}
${green}[Info]${reset} Convert time is $(date -d@"$progTime" -u +%H:%M:%S)

"

else
	message="${green}[Info]${reset} Finish converting all files\n\n"
fi

	;;
	8)	message="${red}[Error]${reset} \t${commandName} is not installed\n";;
	9)	message="${green}[Info]${reset} \tUsing unzip...\n${green}[Info]${reset} \tPlease note that unzip does not work all archives\n\n";;
	10)	message="\tPlease install ImageMagick\n\n";;
	11) message="${green}[Info]${reset} \t${commandName} is installed at ${commandPath}\n";;
	12)	message="Exiting...\n\n"
	;;
	13)	message="\n\t${red}[Error]${reset} Not a valid directory\n\n";;
	14)
		message="
	Usage:	./cbr2pdf.sh --option --option \e[4mVALUE${reset}

	Options:

	[-v|--verbose]			Enable verbose output
	[-x|--extract]			Only extract files without converting
	[-h|--help]			Displays this message
	[-i|--input \e[4m\"DIRECTORY\"${reset}]	The input path for the files
	[-o|--output \e[4m\"DIRECTORY\"${reset}]	The output path for the converted files

	This bash script convert all comic book archives with the 
	file extension .cbr or .cbz recursively from a folder 
	to PDF files in a seperate folder.

	This script mainly uses ImageMagick to convert the images
	to pdf files and 7zip/p7z to extract the archives.

	${yellow}[NOTE]${reset} Both folders must already exist before starting this script
	${yellow}[NOTE]${reset} This script uses commands from the GNU Core Utils
	${yellow}[NOTE]${reset} For MacOS, the date command doesn't work the same way as it is in Linux
	"
	;;
	15)	message="Unknown option: $arg\n\n"
esac
printf "${message}"

}

# Start script

# Declaring color variables
green="\e[32m\e[1m"
red="\e[31m\e[1m"
yellow="\e[33m\e[1m"
reset="\e[0m"

# Reseting variables on startup
VERBOSE=false
EXTRACT=false
HELP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	    -v|--verbose)
	        VERBOSE=true
	        shift
	    ;;

	    -x|--extract)
			EXTRACT=true
			shift
		;;
	    -h|--help)
			HELP=true
			shift
		;;
	    -i|--input)
	        INPUT_PATH="$2"
	        shift
	        shift
	    ;;
	    -o|--output)
	        OUTPUT_PATH="$2"
	        shift
	        shift
	    ;;
	    -*|*)
			arg="$1"
	        message 15
	        message 13
	        exit 1
	esac
done

trap 'exit 1' INT
preRun
main
