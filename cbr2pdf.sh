#!/usr/bin/env bash
# shellcheck disable=SC1117
# shellcheck disable=SC2059

# ========== Formating ====================================================
# This section delclares all of the text formatting required when printing
# information like color codes and linebreaks.

green=$'\e[32m'
red=$'\e[31m'
yellow=$'\e[33m'
reset=$'\033[0m'
underline=$'\e[4m'
bold=$'\e[1m'
linebreak=$'================================================'

box="[!]"
info="${green}${bold}${box}${reset}"
warning="${yellow}${bold}${box}${reset}"
error="${red}${bold}${box}${reset}"
yn="${green}y${reset}/${red}n${reset}"

# ========== Variables ====================================================
# This section exist so that printing out these variables where they are
# not assigned a value, like true, will not result in a blank string.
# Thus they are assigned false before the script starts, then they will
# get assigned true if enabled.

export {verbose,extract,help,keep_file}="false"
export {quiet,debut,input,output}="false"
export {single_file,skip_spinner}="false"
export {skip_summary,skip_list,useConvert}="false"

export {input_dir,output_dir}="null"

file_list_input=()
file_list_sort=()
fail_to_convert=()
able_to_convert=()
incompatible=()

old_ifs="${IFS}"
version="2.3"
working_directory="$(pwd)"

# ========== Functions ====================================================

prin() {

# This function will only print arguments unless the quiet option
# is enabled

	if [[ "$quiet" == "true" ]]; then
		return 1
	fi

	printf "$@"

}

print_file_info() { 

# This section prints out the file information using the pre-defined
# color codes and formatting.

	prin "%s\n" "${linebreak}"
	prin "%s\n" "${info} File information"
	prin "%s\n" "${linebreak}"
	
	prin "%s\n" "${green}${bold}Job Number${reset}:		${count}/${total}"
	prin "%s\n" "${green}${bold}Output Directory${reset}:	${output_file}"
	if [[ "$verbose" == "true" ]]; then
		prin "%s\n" "${green}${bold}Parent Directory${reset}:	${parent}"
		prin "%s\n" "${green}${bold}Source Directory${reset}:	${source_dir}"
		prin "%s\n" "${green}${bold}File Type${reset}:		${source_ext}"
	fi
	prin "%s\n\n" "${green}${bold}Source File${reset}:		${inputFile}"

}

print_summary() {

# This section prints out the conversion summary after
# all files have been processed

	if [[ "$skip_summary" != "true" ]]; then

		prin "%s\n" "${linebreak}"
		prin "%s\n" "${info} Completed files"
		prin "%s\n" "${linebreak}"
		prin "%s\n" "${able_to_convert[@]}"
		prin "\n"

		if [[ ${#incompatible[@]} -gt 0 ]]; then
			prin "%s\n" "${linebreak}"
			prin "%s\n" "${warning} Incompatible files"
			prin "%s\n" "${linebreak}"
			prin "%s\n" "${incompatible[@]}"
			prin "\n"
		fi

	fi

	if [[ ${#fail_to_convert[@]} -gt 0 ]]; then
		prin "%s\n" "${linebreak}"
		prin "%s\n" "${error} Failed to convert ${#fail_to_convert[@]} files"
		prin "%s\n" "${linebreak}"
		prin "%s\n" "${fail_to_convert[@]}"
		prin "\n"
	fi

	prin "%s\n" "${linebreak}"
	if [[ "$extract" != true ]]; then
		prin "%s\n" "${info} Finish converting all files"
	else
		prin "%s\n" "${info} Finish extracting all files"
	fi
	prin "%s\n\n" "${linebreak}"

}

print_if_verbose() {

# Print a new line if verbose is enabled

	if [[ "$verbose" == "true" ]]; then
		prin "\n%s\n" "${linebreak}"
	fi

}

get_file_list() {

# This function will add the list of files to convert
# into an array. The array is then sorted.

	while read -r i; do
		file_list_input+=("${i}")
	done < <(find "${input_dir}" -type f)

	IFS=$'\n' file_list_sort=("$(sort <<<"${file_list_input[*]}")")
	IFS="${old_ifs}"

	unset file_list_input
	while read -r i; do
		file_list_input+=("${i}")
	done < <(printf "%s\n" "${file_list_sort[@]}")
	unset file_list_sort

}

print_file_list() {

# This function prints out the list of files to convert

	if [[ "$skip_list" == "true" ]]; then
		return 0
	fi

	prin "%s\n" "${linebreak}"
	prin "%s\n" "${info} File list"
	prin "%s\n" "${linebreak}"
	prin "%s\n" "${file_list_input[@]}"
	prin "\n"

}

get_full_path() {

# This function finds the absolute path from a relative one.

	if [[ -f "$1" ]]; then						# A condition to check if using single file
		local filename="${1##*/}"				# Create a local variable for filename
		full_path="$(cd "${1%/*}" || exit; pwd -P)/${filename}"
	else
		full_path="$(cd "$1" || exit; pwd -P)"	# Change to the directory and get the parent directory
	fi

	cd "${working_directory}" || exit			# Change back to the original working directory
	printf "%s\n" "${full_path%/}"				# Print out the full directory as well as trim trailing slash

}

extract() {

# This section extract files through the parsed arguments.

	prin "%s" "${info} Extracting archive..." && print_if_verbose

	# Assign parsed options into one string for case to parse easily
	local evqs="${extractor} ${verbose:0:1} ${quiet:0:1} ${skip_spinner:0:1}"
	case "$evqs" in
		"7z t"*)		7z x "$1" -o"$2" ;;							# Verbose only
		"7z f f t"| \
		"7z f t f"| \
		"7z f t t")		7z x "$1" -o"$2" &> /dev/null ;;			# Quiet or no spinner
		"7z f f f")		7z x "$1" -o"$2" &> /dev/null; spinner ;;	# Spinner only
		"7za t"*)		7za x "$1" -o"$2" ;;
		"7za f f t"| \
		"7za f t f"| \
		"7za f t t")	7za x "$1" -o"$2" &> /dev/null ;;
		"7za f f f")	7za x "$1" -o"$2" &> /dev/null; spinner ;;
		"unzip t"*)		unzip "$1" -d "$2" ;;
		"unzip f f t"| \
		"unzip f t f"| \
		"unzip f t t")	unzip "$1" -d "$2" &> /dev/null ;;
		"unzip f f f")	unzip "$1" -d "$2" &> /dev/null; spinner ;;
	esac

}

checkFolder() {

# Sometimes, the images are within a folder after extraction
# This detects if there is a subfolder after extraction and
# moves the files up one level

	check="$(find "$1" -type d -maxdepth 2 | sed -n '2 p')"

	if [[ -z "$check" ]]; then
		prin "\n%s" "${info} No subfolders detected..." && print_if_verbose
	else
		prin "\n%s" "${info} Subfolders detected, moving..." && print_if_verbose
		if [[ "$verbose" == "true" ]]; then
			mv -v "${check}"/* "$1"
		else
			mv "${check}"/* "$1"
		fi
		rmdir "${check}"
	fi

}

checkExtension() {

# Conversion will fail if the file extension does not
# match due to a difference in case. This function
# will individually check each extracted images to
# ensure that they are all lowercase.

	prin "\n%s" "${info} Checking Extension..."

	while read -r check; do

		local file="${check##*/}"
		local filename="${file%.*}"				# Get filename
		local file_ext="${file##*.}"			# Get file extension

		# Condition to check if the file extension is already lowercase
		if [[ "$file_ext" == "jpg" ]] || [[ "$file_ext" == "png" ]]; then
			local return_code=0
		else
			# If it isn't, then rename file to a lowercase extension
			if [[ "$verbose" == "true" ]]; then
				mv -v "$check" "${output_filename}/${filename}.${file_ext,,}"
			else
				mv "$check" "${output_filename}/${filename}.${file_ext,,}"
			fi
			local return_code=1

		fi

	done < <(find "$1" -type f)

	if [[ "$return_code" == 0 ]]; then
		prin "\r%s" "${info} Extension case matches..." && print_if_verbose
	elif [[ "$return_code" == 1 ]]; then
		prin "\r%s" "${info} Extension case not match, changing..." && print_if_verbose
	fi

}

convertFile() {

# Convert .jpg to .pdf

	# Exit if extract flag is set to true
	if [[ "$extract" == "true" ]]; then
		return 0
	fi

	prin "\n%s" "${info} Converting to PDF..." && print_if_verbose

	# Assign parsed options into one string for case to parse easily
	local vqs="${verbose:0:1} ${quiet:0:1} ${skip_spinner:0:1}"
	case "$vqs" in
		"t"*)		convert "$1" -density 100 -verbose "$2" ;;
		"f f t"| \
		"f t f"| \
		"f t t")	convert "$1" -density 100 "$2" ;;
		"f f f")	convert "$1" -density 100 "$2" &
					spinner ;;
	esac

}

delete() {

# Delete the extracted files

	if [[ "$extract" == "true" ]] || [[ "$keep_file" == "true" ]]; then
		return 0
	fi

	prin "\n%s" "${info} Deleting extracted files..." && print_if_verbose
	if [[ "$verbose" == "true" ]]; then
		rm -rfv "$1"
	else
		rm -rf "$1"
	fi

}

spinner() {

# Referenced from http://fitnr.com/showing-a-bash-spinner.html
# By Louis Marascio

	local pid="$!"
	local delay=0.1
	local spinstr='/-\|'
	while ps a | awk '{print $1}' | grep -q "$pid"; do
		local temp="${spinstr#?}"
		printf " (%c)  " "$spinstr"
		local spinstr="$temp${spinstr%"$temp"}"
		sleep "$delay"
		printf "\b\b\b\b\b\b"
	done
	printf "    \b\b\b\b"

}

get_args() {
	
# Determing the parsed arguments

	# If no arguments are parsed, print help and exit
	if [[ -z "$1" ]]; then	
		usage print
		printf "%s\n\n" "${error} No options specified"
		exit 2
	fi

	while [[ "$#" -gt 0 ]]; do
		case "$1" in
			"-v"|"--verbose") verbose="true"; quiet="false" ;;
			"-x"|"--extract") extract="true" ;;
			"-h"|"--help") usage; help="true" ;;
			"-k"|"--keep") keep_file="true" ;;
			"-q"|"--quiet") quiet="true"; verbose="false" ;;
			"-i"|"--input") input_dir="$2"; shift; input="true" ;;
			"-o"|"--output") output_dir="$2"; shift; output="true" ;;
			"-d"|"--debug") debug="true"; quiet="false"; set -x ;;
			"--version") version ;;
			"--no-spinner") skip_spinner="true" ;;
			"--no-summary") skip_summary="true" ;;
			"--no-color") reset_colors ;;
			"--no-list") skip_list="true" ;; 
	    	-*|*) arg="$1"; usage print_error ;;
		esac
		shift
	done

}

print_debug() {

# Print debug information

	if [[ "$debug" == "true" ]]; then
		prin "\n%s\n" "verbose: 	${verbose}"
		prin "%s\n" "extract: 	${extract}"
		prin "%s\n" "help: 		${help}"
		prin "%s\n" "input: 		${input}"
		prin "%s\n" "output: 	${output}"
		prin "%s\n" "debug: 		${debug}"
		prin "%s\n" "input_dir:	${input_dir}"
		prin "%s\n\n" "output_dir: 	${output_dir}"
	fi

}

print_verbose() {

# Print verbose information

	if [[ "$verbose" == "true" ]]; then
		prin "\n%s\n" "${green}${bold}Verbose Output${reset}: ${verbose}"
		prin "%s\n" "${green}${bold}Extract Only${reset}:	${extract}"
		prin "%s\n" "${green}${bold}Input${reset}: 		${input_dir}"
		prin "%s\n\n" "${green}${bold}Output${reset}: 	${output_dir}"
	fi

}

check_dir() {

# Check if the input and output directory exist
# If they are not, it will print the usage message, error message and exit

	# Find absolute paths for input and output
	
	input_dir="$(get_full_path "${input_dir}")"
	output_dir="$(get_full_path "${output_dir}")"

	# If the output option is not specified, then create an "Output" folder
	# in the current working directory

	if [[ "$output_dir" == "null" ]]; then
		output_dir="${working_directory}/Output"
		mkdir -p "${output_dir}"
	fi

	# Trim off the slash at the end of the directories as they break the script
	input_dir="${input_dir%/}"
	output_dir="${output_dir%/}"

	if [[ ! -d "$input_dir" ]]; then
		if [[ -f "$input_dir" ]]; then
			single_file="true"
		else
			usage print
			prin "%s\n\n" "${error} Input directory is not a valid directory"
			exit 2
		fi
	fi
	
	if [[ ! -d "$output_dir" ]]; then
		prin "\n%s\n" "${warning} Output directory is not a valid directory"
		prin "%s" "${warning} Do you want to create the output directory? [${yn}] "
		read -r a
		if [[ "$a" =~ ^[Yy]$ ]]; then
			mkdir "${output_dir}"
			prin "\n"
		else
			prin "\n%s\n\n" "${error} Exiting..."
			exit 2
		fi
	fi

}

check_app() {

# Check if the program exist, if not then it will state that it is not installed
# and exit the script.
	
# If p7z is not installed, the script will fallback to unzip instead. However,
# due to how some comic archives are compressed, unzip might not be able to 
# extract those files, thus why p7z is used

	if type -p 7z >/dev/null 2>&1; then
		extractor="7z"
	fi
	if type -p 7za >/dev/null 2>&1 && [[ -z "$extractor" ]]; then
		extractor="7za"
	fi
	if type -p unzip >/dev/null 2>&1 && [[ -z "$extractor" ]]; then
		extractor="unzip"
	fi
	if type -p convert >/dev/null 2>&1; then
		useConvert="true"
	fi

	# Print verbose/debug information
	if [[ "$verbose" == "true" ]] || [[ "$debug" == "true" ]]; then
		prin "%s\n" "${green}${bold}Extractor${reset}:		${extractor}"
	fi

	if [[ "$extractor" == "unzip" ]]; then
		prin "%s\n" "${warning} 7z is not installed, falling back to Unzip"
	fi

	if [[ -z "$extractor" ]]; then
		prin "%s\n" "${error} Unzip and 7z is not installed."
		prin "%s\n\n" "${error} Exiting..."
		exit 3
	fi

	if [[ "$useConvert" != "true" ]]; then
		prin "%s\n" "${error} ImageMagick is not installed."
		prin "%s\n\n" "${error} Exiting..."
		exit 3
	fi

}

usage() { 

# This function prints out the usage message

printf "%s\n" "\

Usage:	./cbr2pdf.sh --option --option ${underline}VALUE${reset}

	Options:

	[-v|--verbose]			Enable verbose output
	[-x|--extract]			Only extract files
	[-h|--help]			Displays this message
	[-k|--keep]			Keep extracted files
	[-q|--quiet]			Suppress all output
	[-i|--input ${underline}\"DIRECTORY\"${reset}]	The input path for the files
	[-o|--output ${underline}\"DIRECTORY\"${reset}]	The output path for the converted files
	[-d|--debug]			Shows debug information
	[--version]			Print version number
	[--no-spinner]			Disable the spinner
	[--no-summary]			Disable printing summary (still print failed)
	[--no-color]			Disable color output
	[--no-list]			Disable printing file listing

	This bash script convert all comic book archives with the 
	file extension .cbr or .cbz recursively from a folder 
	to PDF files in a seperate folder. It can also do single
	files.

	This script mainly uses ImageMagick to convert the images
	to pdf files and 7zip/p7z to extract the archives.

	Made by Julian Heng

${warning} Both folders must already exist before starting this script
" 

# By default, this function will exit the program. If we parsed
# "print" into the function it will just print and not exit

	if [[ "$1" == "print_error" ]]; then
		prin "%s\n\n" "${error} Unknown option: ${arg}"
		exit 2
	fi
	
	if [[ "$1" != "print" ]]; then
		exit 0
	fi

}

version() {

printf "%s\n" "\

${linebreak}
Version: cbr2pdf.sh ${green}${bold}${version}${reset}
Made by Julian Heng, 17/12/2017
${linebreak}
"
exit 0

}

reset_colors() {

	unset green
	unset red
	unset yellow
	unset bold

	info="${box}"
	warning="${box}"
	error="${box}"
	yn="y/n"

}

main() {

	trap 'exit 1' INT
	get_args "$@"
	print_debug
	print_verbose
	check_dir
	check_app

	get_file_list
	print_file_list

	# Get counter information
	total="${#file_list_input[@]}"
	count=1

	while read -r inputFile; do	
		parent="${input_dir%/*}"						# Get parent directory
		source_dir="${inputFile%/*}"					# Get the source directory
		source_file="${inputFile##*/}"					# Get the source filename
		source_filename="${source_file%.*}"				# Format the source filename
		source_ext="${source_file##*.}"					# Get the source file extension
		if [[ "$single_file" != "true" ]]; then			# Check if converting one file
			output_file="${source_dir#$parent}"			# Get destination directory
		fi
		output_file="${output_dir}${output_file}"		# Format the destination directory
		output_filename="${output_file}/${source_filename}"

		# Make the output folder
		mkdir -p "${output_file}"

		# Detects the file type and skip if it's not a comic book archive
		if [[ "${source_ext,,}" == "cbr" ]] || [[ "${source_ext,,}" == "cbz" ]]; then

			# Print file and directory information
			print_file_info

			# Make output directory
			mkdir -p "${output_filename}"

			# Extract, check, convert and delete
			extract "${inputFile}" "${output_filename}"
			checkFolder "${output_filename}"
			checkExtension "${output_filename}"
			convertFile "${output_filename}/*.{jpg,png}" "${output_filename}.pdf"
			delete "${output_filename}"

			# Determine if the converting succeeded.
			# If it did, then add the filename to the array of completed
			# If it didn't, then add the filename to the array of incomplete
			if [[ "$extract" == "true" ]]; then
				if [[ ! -z "$(find "${output_filename}" -type f)" ]]; then
    				able_to_convert+=("${inputFile}")
    				prin "\n%s\n\n" "${info} Finish extracting \"${source_file}\""
				else
					fail_to_convert+=("${inputFile}")
					prin "\n%s\n\n" "${error} Failed to extract \"${source_file}\""
				fi
			else
				if [[ -f "${output_filename}.pdf" ]]; then
					able_to_convert+=("${inputFile}")
					prin "\n%s\n\n" "${info} Finish converting \"${source_file}\""
				else
					fail_to_convert+=("${inputFile}")
					prin "\n%s\n\n" "${error} Failed to convert \"${source_file}\""
				fi
			fi

		else

			# If the file is not a comic book archive,
			# then print file info, add to array and skip
			print_file_info
			incompatible+=("${inputFile}")
			prin "%s\n\n" "${warning} Not a compatible file. Skipping..."

		fi

		# Increment job counter
		((++count))

	done < <(printf "%s\n" "${file_list_input[@]}")

	print_summary

}

# ========== Start Script ====================================================

main "$@"