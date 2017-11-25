#!/usr/bin/env bash



# ========== Formating ====================================================
# This section delclares all of the text formatting required when printing
# information like color codes and linebreaks.

green=$'\e[32m\e[1m'
red=$'\e[31m\e[1m'
yellow=$'\e[33m\e[1m'
reset=$'\033[0m'
underline=$'\e[4m'
linebreak=$'================================================'

infobox="${green}[Info]${reset}"
warningbox="${yellow}[Warning]${reset}"
errorbox="${red}[Error]${reset}"

# ========== Variables ====================================================
# This section exist so that printing out these variables where they are
# not assigned a value, like true, will not result in a blank string.
# Thus they are assigned false before the script starts, then they will
# get assigned true if enabled.

verbose=false
extract=false
help=false
input=false
output=false

# ========== Functions ====================================================

print_file_info() { 

# This section prints out the file information using the pre-defined
# color codes and formatting.

printf "%s\n" "${linebreak}"
printf "%s File information\n" "${infobox}"
printf "%s\n" "${linebreak}"
printf "%sJob Number%s:		%s/%s\n" "${green}" "${reset}" "${count}" "${total}"
printf "%sOutput Directory%s:	%s\n" "${green}" "${reset}" "${output}"
if [[ $verbose = true ]] || [[ $debug = true ]]; then
	printf "%sParent Directory%s:	%s\n" "${green}" "${reset}" "${parent}"
	printf "%sSource Directory%s:	%s\n" "${green}" "${reset}" "${source_dir}"
	printf "%sFile Type%s:		%s\n" "${green}" "${reset}" "${source_ext}"
fi
printf "%sSource File%s:		%s\n\n" "${green}" "${reset}" "${inputFile}"

}

print_if_verbose() {

# Print a new line if verbose/debug is enabled

	if [[ $verbose = true ]]; then
		printf "\n%s\n" "${linebreak}"
	else
		:
	fi

}

extract() {

# This section extract files through the parsed arguments.

	printf "%s Extracting archive..." "${infobox}"
	if [[ $use7z = false ]]; then
		if [[ $verbose = true ]]; then
			unzip "$1" -d "$2"
		else
			unzip "$1" -d "$2" &> /dev/null; spinner
		fi
	else
		if [[ $verbose = true ]]; then
			7z x "$1" -o"$2"
		else
			7z x "$1" -o"$2" &> /dev/null; spinner
		fi
	fi

}

checkFolder() {

# Sometimes, the images are within a folder after extraction
# This detects if there is a subfolder after extraction and
# moves the files up one level

	check=$(find "$1" -type d -maxdepth 2 | sed -n '2 p')

	if [[ $check == "" ]]; then
		printf "\n%s No subfolders detected..." "${infobox}"; print_if_verbose
	else
		printf "\n%s Subfolders detected, moving..." "${infobox}"; print_if_verbose
		if [[ $verbose = true ]]; then
			mv -v "${check}"/* "$1"
		else
			mv "${check}"/* "$1"
		fi
		rmdir "${check}"
	fi

}

convertFile() {

# Convert .jpg to .pdf

	printf "\n%s Converting to PDF..." "${infobox}"; print_if_verbose
	if [[ $verbose = true ]]; then
		convert "$1" -density 100 -verbose "$2"
	else
		convert "$1" -density 100 "$2" &
		spinner
	fi

}

delete() {

# Delete the extracted files

	printf "\n%s Deleting extracted files..." "${infobox}"; print_if_verbose
	if [[ $verbose = true ]]; then
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
	local spinstr='/-\|'
	while ps a | awk '{print $1}' | grep -q $pid; do
		local temp=${spinstr#?}
		printf " [%c]  " "$spinstr"
		local spinstr=$temp${spinstr%"$temp"}
		sleep $delay
		printf "\b\b\b\b\b\b"
	done
	printf "    \b\b\b\b"

}

get_args() {
	
# Determing the parsed arguments

	# If no arguments are parsed, print help and exit
	if [[ -z $1 ]]; then	
		usage print
		printf "%s No options specified\n\n" "${errorbox}"
		exit 2
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-v|--verbose) verbose=true ;;
			-x|--extract) extract=true ;;
			-h|--help) usage; help=true ;;
			-i|--input) input_dir="$2"; shift; input=true ;;
			-o|--output) output_dir="$2"; shift; output=true ;;
			-d|--debug) debug=true; set -x ;;
	    	-*|*) usage print; printf "%s Unknown option: $1\n\n" "${errorbox}"; exit 2
		esac
		shift
	done

}

print_debug() {

# Print debug information

	if [[ -z $input_dir ]]; then
		input_dir=null
	fi
	if [[ -z $output_dir ]]; then
		output_dir=null
	fi

	if [[ $debug == true ]]; then
		printf "\nverbose: 	%s\n" "${verbose}"
		printf "extract: 	%s\n" "${extract}"
		printf "help: 		%s\n" "${help}"
		printf "input: 		%s\n" "${input}"
		printf "output: 	%s\n" "${output}"
		printf "debug: 		%s\n" "${debug}"
		printf "input_dir: 	%s\n" "${input_dir}"
		printf "output_dir: 	%s\n\n" "${output_dir}"
	fi

}

print_verbose() {

# Print verbose information

	if [[ $verbose == true ]]; then
		printf "\n%sVerbose Output%s: %s\n" "${green}" "${reset}" "${verbose}"
		printf "%sExtract Only%s:	%s\n" "${green}" "${reset}" "${extract}"
		printf "%sInput%s: 		%s\n" "${green}" "${reset}" "${input_dir}"
		printf "%sOutput%s: 	%s\n\n" "${green}" "${reset}" "${output_dir}"
	fi

}

check_dir() {

# Check if the input and output directory exist
# If they are not, it will print the usage message, error message and exit

	# Trim off the slash at the end of the directories as they break the script
	input_dir=${input_dir%/}
	output_dir=${output_dir%/}

	if [[ ! -d $input_dir ]]; then
		usage print
		printf "%s Input directory is not a valid directory\n\n" "${errorbox}"
		exit 2
	fi
	
	if [[ ! -d $output_dir ]]; then
		usage print
		printf "%s Output directory is not a valid directory\n\n" "${errorbox}"
		exit 2
	fi

}

check_app() {

# Check if the program exist, if not then it will state that it is not installed
# and exit the script.
	
# If p7z is not installed, the script will fallback to unzip instead. However,
# due to how some comic archives are compressed, unzip might not be able to 
# extract those files, thus why p7z is used

	if type -p 7z >/dev/null 2>&1; then
		use7z=true
	else
		use7z=false
	fi
	if type -p unzip >/dev/null 2>&1; then
		useUnzip=true
	else
		useUnzip=false
	fi
	if type -p convert >/dev/null 2>&1; then
		useConvert=true
	else
		useConvert=false
	fi

	# Print verbose/debug information
	if [[ $verbose = true ]] || [[ $debug = true ]]; then
		printf "%suse7z%s:		%s\n" "${green}" "${reset}" "${use7z}"
		printf "%suseConvert%s:	%s\n" "${green}" "${reset}" "${useConvert}"
		printf "%suseUnzip%s:	%s\n\n" "${green}" "${reset}" "${useUnzip}"
	fi

	if [[ $use7z = false ]]; then
		printf "%s 7z is not installed, falling back to Unzip\n" "${warningbox}"
	fi

	if [[ $useUnzip = false ]]; then
		printf "%s Unzip and 7z is not installed.\n" "${errorbox}"
		printf "Exiting...\n\n"
		exit 3
	fi

	if [[ $useConvert = false ]]; then
		printf "%s ImageMagick is not installed.\n" "${errorbox}"
		printf "Exiting...\n\n"
		exit 3
	fi

}

usage() { 

# This function prints out the usage message

printf "\
Usage:	./cbr2pdf.sh --option --option %sVALUE%s

	Options:

	[-v|--verbose]			Enable verbose output
	[-x|--extract]			Only extract files without converting
	[-h|--help]			Displays this message
	[-i|--input %s\"DIRECTORY\"%s]	The input path for the files
	[-o|--output %s\e[4m\"DIRECTORY\"%s]	The output path for the converted files
	[-d|--debug]			Shows debug information

	This bash script convert all comic book archives with the 
	file extension .cbr or .cbz recursively from a folder 
	to PDF files in a seperate folder.

	This script mainly uses ImageMagick to convert the images
	to pdf files and 7zip/p7z to extract the archives.

%s[NOTE]%s Both folders must already exist before starting this script

" \
"${underline}" "${reset}" \
"${underline}" "${reset}" \
"${underline}" "${reset}" \
"${yellow}" "${reset}"

# By default, this function will exit the program. If we parsed
# "print" into the function it will just print and not exit
if [[ "$1" != "print" ]]; then
	exit 1
fi

}

main() {

	trap 'exit 1' INT
	get_args "$@"
	print_debug
	print_verbose
	check_dir
	check_app

	# Get counter information
	total=$(find "${input_dir}" -type f | wc -l)
	total=${total// /}
	count=1

	while read -r inputFile; do
		parent=$(dirname "${input_dir}")			# Get parent directory
		source_dir=${inputFile%/*}					# Get the source directory
		source_file=${inputFile##*/}				# Get the source file
		source_filename=$(basename "$inputFile")	# Get the source filename
		source_filename=${source_filename%.*}		# Format the source filename
		source_ext=${inputFile##*.}					# Get the source file extension
		output=${source_dir#$parent}				# Get destination directory
		output=${output_dir}/${output#/}			# Format the destination directory

		# Make the output folder
		mkdir -p "${output}"

		# Detects the file type and skip if it's not a comic book archive
		if [[ $source_ext == "cbr" ]] || [[ $source_ext == "cbz" ]]; then

			# Print file and directory information
			print_file_info

			# Make output directory
			mkdir -p "${output}/${source_filename}"

			# Extract, check, convert and delete
			extract "${inputFile}" "${output}/${source_filename}"
			checkFolder "${output}/${source_filename}"

			# If extract only option is parsed, then skip converting and deleting
			if [[ $extract != true ]]; then
				convertFile "${output}/${source_filename}/*.{jpg,png}" "${output}/${source_filename}.pdf"
				delete "${output}/${source_filename}"
				printf "\n%s Finish converting %s\n\n" "${infobox}" "${source_file}"
			else
				printf "\n%s Finish extracting %s\n\n" "${infobox}" "${source_file}"
			fi
		else

			# If the file is not a comic book archive, then print file info and skip
			print_file_info
			printf "%s Not a compatible file. Skipping...\n\n" "${warningbox}"

		fi

		# Increment job counter
		((++count))
	done < <(find "${input_dir}" -type f)
	printf "%s\n" "${linebreak}"
	if [[ $extract != true ]]; then
		printf "%s Finish converting all files\n" "${infobox}"
	else
		printf "%s Finish extracting all files\n" "${infobox}"
	fi
	printf "%s\n\n" "${linebreak}"

}

# ========== Start Script ====================================================

main "$@"