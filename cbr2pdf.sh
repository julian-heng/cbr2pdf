#!/usr/bin/env bash
# shellcheck disable=SC1117
# shellcheck disable=SC2059
# shellcheck disable=SC2195

# ========== Formating ====================================================
# This section delclares all of the text formatting required when printing
# information like color codes and linebreaks.

green=$'\e[32m'
red=$'\e[31m'
yellow=$'\e[33m'
reset=$'\e[0m'
underline=$'\e[4m'
bold=$'\e[1m'
line="================================================"

box="[!]"
info="${green}${bold}${box}${reset}"
warning="${yellow}${bold}${box}${reset}"
error="${red}${bold}${box}${reset}"
tick="${green}${bold}[✓]${reset}"
yn="${green}y${reset}/${red}n${reset}"

# ========== Variables ====================================================
# This section exist so that printing out these variables where they are
# not assigned a value, like true, will not result in a blank string.
# Thus they are assigned false before the script starts, then they will
# get assigned true if enabled.

export {verbose,extract,help,keep_file,quiet,single_file,overwrite}="false"
export {parallel,skip_spinner,skip_summary,skip_list,useConvert}="false"

export {input_dir,output_dir}="null"
export {p_amount,total,count}=0
export log_level=2

file_list_input=()
fail_to_convert=()
able_to_convert=()
incompatible=()
existed=()

old_ifs="${IFS}"
version="2.6"
working_directory="$(pwd)"

# ========== Printing Functions ===========================================

print_if_verbose() {

# Print a new line if verbose is enabled

	[[ "$quiet" == "true" ]] && return 0
	[[ "$verbose" == "true" ]] && printf "\n%s\n" "${line}"

}

print_verbose() {

# Print verbose information

	if [[ "$verbose" == "true" ]]; then
		printf "\n%s\n" "${green}${bold}Verbose Output${reset}: ${verbose}"
		printf "%s\n" "${green}${bold}Extract Only${reset}:	${extract}"
		printf "%s\n" "${green}${bold}Keep${reset}: 		${keep_file}"
		printf "%s\n" "${green}${bold}Input${reset}: 		${input_dir}"
		printf "%s\n" "${green}${bold}Output${reset}: 	${output_dir}"
		printf "%s\n" "${green}${bold}Log Level${reset}: 	${log_level}"
		printf "%s\n" "${green}${bold}Overwrite${reset}: 	${overwrite}"
		printf "%s\n\n" "${green}${bold}Parallel${reset}: 	${p_amount} threads"
	fi

}

print_header() {

# Prints header information

	case "$1" in
		info)	printf "%s\n%s\n%s\n" "${line}" "${info} ${2}" "${line}" ;;
		warn)	printf "%s\n%s\n%s\n" "${line}" "${warning} ${2}" "${line}" ;;
		error)	printf "%s\n%s\n%s\n" "${line}" "${error} ${2}" "${line}" ;;
	esac

}

print_file_info() { 

# This section prints out the file information using the pre-defined
# color codes and formatting.

	if ((log_level >= 2)); then
		print_header "info" "File information"

		printf "%s\n" "${green}${bold}Job Number${reset}:		${count}/${total}"
		printf "%s\n" "${green}${bold}Output Directory${reset}:	${output_file}"
		if [[ "$verbose" == "true" ]]; then
			printf "%s\n" "${green}${bold}Parent Directory${reset}:	${parent_dir}"
			printf "%s\n" "${green}${bold}Source Directory${reset}:	${source_dir}"
			printf "%s\n" "${green}${bold}File Type${reset}:		${source_ext}"
		fi
		printf "%s\n\n" "${green}${bold}Source File${reset}:		${input_file}"
	fi

}

print_file_list() {

# This function prints out the list of files to convert

	[[ "$skip_list" == "true" ]] && return 0

	if ((log_level >= 2)); then
		print_header "info" "File list"

		if [[ "$parallel" != "true" ]]; then
			printf "%s\n" "${file_list_input[@]}"
			printf "\n"
		fi
	fi

}

print_split_list() {

# This function prints out the list of files to convert after
# the input list has been seperated into 4 groups

	[[ "$skip_list" == "true" ]] && return 0

	if ((log_level >= 2)); then
		printf "%s\n%s\n" "${green}${bold}Group 1:${reset}" "${group_1[@]}"
		printf "\n"

		if ((${#group_2[@]} > 0)); then
			printf "%s\n%s\n" "${green}${bold}Group 2${reset}:" "${group_2[@]}"
			printf "\n"

			if ((${#group_3[@]} > 0)); then
				printf "%s\n%s\n" "${green}${bold}Group 3${reset}:" "${group_3[@]}"
				printf "\n"

				if ((${#group_4[@]} > 0)); then
				printf "%s\n%s\n" "${green}${bold}Group 4${reset}:" "${group_4[@]}"
				fi
			fi
		fi
	fi

}

print_log() {

# This function prints info depending on the log level

	[[ "$quiet" == "true" ]] && return 0

	# Return if log_level is not 1
	if ((log_level >= 2)); then

		# Print console messages 
		case "$1" in
			"extract")
				case "$2" in
					"message") printf "%s" "${info} Extracting archive..." && print_if_verbose ;;
					"parallel_message") printf "%s" "Extracting in parallel with ${green}${bold}[${p_amount}]${reset} threads..." ;;
					"success") printf "\n%s\n\n" "${tick} Finish extracting \"${source_file}\"" ;;
					"fail") printf "\n%s\n\n" "${error} Failed to extract \"${source_file}\"" ;;
				esac
			;;

			"convert")
				case "$2" in
					"message") printf "\n%s" "${info} Converting to PDF..." && print_if_verbose ;;
					"parallel_message") printf "%s" "Converting in parallel with ${green}${bold}[${p_amount}]${reset} threads..." ;;
					"success") printf "\n%s\n\n" "${tick} Finish converting \"${source_file}\"" ;;
					"fail") printf "\n%s\n\n" "${error} Failed to convert \"${source_file}\"" ;;
				esac
			;;

			"check_folder") 
				case "$2" in
					"false") printf "\n%s" "${info} No subfolders detected..." && print_if_verbose ;;
					"true") printf "\n%s" "${info} Subfolders detected, moving..." && print_if_verbose ;;
				esac
			;;

			"check_extension")
				case "$2" in
					"message") printf "\n%s" "${info} Checking Extension..." ;;
					"success") printf "\r%s" "${info} Extension case matches..." && print_if_verbose ;;
					"fail") printf "\r%s" "${info} Extension case not match, changing..." && print_if_verbose ;;
				esac
			;;

			"delete message") printf "\n%s" "${info} Deleting extracted files..." && print_if_verbose ;;
			"skip" ) printf "%s\n\n" "${info} File existed, skipping..." && print_if_verbose ;;
		esac

	else

		# Case to determine if printing before conversion or after
		case "$1" in
			"before")
				case "$extract" in
					"true") printf "%s" "${info} Extracting \"${source_file}\"" ;;
					"false") printf "%s" "${info} Converting \"${source_file}\"" ;;
				esac
			;;

			"after")
				case "$extract" in
					"true") printf "\r%s\n" "${tick} Finish extracting \"${source_file}\"" ;;
					"false") printf "\r%s\n" "${tick} Finish converting \"${source_file}\"" ;;
				esac
			;;

		esac

	fi

}

print_summary() {

# This section prints out the conversion summary after
# all files have been processed

	[[ "$quiet" == "true" ]] && return 0

	if [[ "$parallel" != "true" ]]; then
		if ((log_level > 1)); then

			if [[ "$skip_summary" != "true" ]]; then
				if ((${#able_to_convert[@]} > 0)); then
					print_header "info" "Completed files"
					printf "%s\n" "${able_to_convert[@]}"
					printf "\n"
				fi

				if ((${#existed[@]} > 0)); then
					print_header "info" "Existed files"
					printf "%s\n" "${existed[@]}"
					printf "\n"
				fi

				if ((${#incompatible[@]} > 0)); then
					print_header "warn" "Incompatible files"
					printf "%s\n" "${incompatible[@]}"
					printf "\n"
				fi

			fi

		fi

		if ((${#fail_to_convert[@]} > 0)); then
			print_header "error" "Failed to convert ${#fail_to_convert[@]} files"
			printf "%s\n" "${fail_to_convert[@]}"
			printf "\n"
		fi

	fi

	if [[ "$extract" != true ]]; then
		print_header "info" "Finish converting all files"
	else
		print_header "info" "Finish extracting all files"
	fi

}

# ========== Eye Candy ====================================================

spinner() {

# Referenced from http://fitnr.com/showing-a-bash-spinner.html
# By Louis Marascio

	local pid="$!"
	local delay=0.5
	local spinstr='/-\|'
	while ps a | awk '{print $1}' | grep -q "${pid}"; do
		local temp="${spinstr#?}"
		printf " (%c)  " "$spinstr"
		local spinstr="$temp${spinstr%"$temp"}"
		sleep "${delay}"
		printf "\b\b\b\b\b\b"
	done
	printf "    \b\b\b\b"

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
	[-p|--parallel ${underline}\"VALUE\"${reset}]		Run in parallel
	[-l|--loglevel ${underline}\"VALUE\"${reset}]		Determine level of output details
	[-w|--overwrite]		Overwrite existing files
	[-i|--input ${underline}\"DIRECTORY\"${reset}]	The input path for the files
	[-o|--output ${underline}\"DIRECTORY\"${reset}]	The output path for the converted files
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

	case "$1" in
		print_error)
				printf "%s\n\n" "${error} Unknown option: ${arg}"
				exit 2 ;;
		print)	return 0 ;;
		*)		exit 0 ;;
	esac

}

version() {

printf "%s\n" "\

${line}
Version: cbr2pdf.sh ${green}${bold}${version}${reset}
Made by Julian Heng, 23/12/2017
${line}
"
exit 0

}

# ========== List Functions ===============================================

get_file_list() {

# This function will add the list of files to convert
# into an array. The array is then sorted.

	while read -r i; do

		# Get file extension
		local file_ext="${i##*.}"

		# Condition to determine if it's an archive
		case "${file_ext,,}" in
			"cbr"|"cbz")	file_list_input+=("${i}") ;;	# Add file path to array
			*)				incompatible+=("${i}") ;;		# Record in incompatible files
		esac

	done < <(find "${input_dir}" -type f | sort)

	# Get counter information
	total="${#file_list_input[@]}"
	count=1

	# Determine if input directory is empty
	if [[ -z "${file_list_input[*]}" ]]; then
		usage "print"
		printf "%s\n\n" "${error} Input directory is empty"
		exit 3
	fi

}

split_list() {

# This function is for parallelisation
# Parallisation is hard coded to have 4 split groups
# at the moment. It is preferable for the number of
# parallelisation processes to be user set. But at the
# moment I can't find a way to implement that function.

	# Skip function if parallel flag is not set
	[[ "$parallel" != "true" ]] && return 0

	case "1:${p_amount:--}" in
		("$((p_amount >= 4))"*)		p_amount=4 ;;
		("$((p_amount >= 2))"*|"")	p_amount=2 ;;
		*)							p_amount=1 ;;
	esac

	# Calculate the amount of files per group
	split_amount="$((total / p_amount))"
	a=0

	IFS=$'\n' 

	group_1=()
	group_2=()
	group_3=()
	group_4=()

	# Setting the files into each group
	# Yes, this is ugly code. Hopefully this can
	# be solved in the future

	case "$p_amount" in
		4)
			while read -r i; do
				group_1+=("${i}")
			done < <(printf "%s\n" "${file_list_input[@]:a:split_amount}")
			a="$((a + split_amount))"

			while read -r i; do
				group_2+=("${i}")
			done < <(printf "%s\n" "${file_list_input[@]:a:split_amount}")
			a="$((a + split_amount))"

			while read -r i; do
				group_3+=("${i}")
			done < <(printf "%s\n" "${file_list_input[@]:a:split_amount}")
			a="$((a + split_amount))"

			while read -r i; do
				group_4+=("${i}")
			done < <(printf "%s\n" "${file_list_input[@]:a}")
		;;

		2)
			while read -r i; do
				group_1+=("${i}")
			done < <(printf "%s\n" "${file_list_input[@]:a:split_amount}")
			a="$((a + split_amount))"

			while read -r i; do
				group_2+=("${i}")
			done < <(printf "%s\n" "${file_list_input[@]:a}")
		;;

		1)
			while read -r i; do
				group_1+=("${i}")
			done < <(printf "%s\n" "${file_list_input[@]}")
		;;
	esac

	IFS="${old_ifs}"

	# Print each group list
	print_split_list

}

# ========== Misc Functions ===============================================

get_args() {

# Determing the parsed arguments

	# If no arguments are parsed, print help and exit
	if [[ -z "$1" ]]; then	
		usage "print"
		printf "%s\n\n" "${error} No options specified"
		exit 2
	fi

	while (($# > 0)); do
		case "$1" in
			"-v"|"--verbose")	log_level=3; verbose="true"; quiet="false" ;;
			"-x"|"--extract")	extract="true" ;;
			"-h"|"--help")		usage ;;
			"-k"|"--keep")		keep_file="true" ;;
			"-q"|"--quiet")		unset log_level; verbose="true"; quiet="false"; skip_spinner="true" ;;
			"-p"|"--parallel")	parallel="true"; p_amount="$2"; shift ;;
			"-l"|"--loglevel")	log_level=$2; shift ;;
			"-w"|"--overwrite")	overwrite="true" ;;
			"-i"|"--input")		input_dir="$2"; shift ;;
			"-o"|"--output")	output_dir="$2"; shift ;;
			"--version")		version ;;
			"--no-spinner")		skip_spinner="true" ;;
			"--no-summary")		skip_summary="true" ;;
			"--no-color")		reset_colors ;;
			"--no-list")		skip_list="true" ;; 
			-*|*)				arg="$1"; usage "print_error" ;;
		esac
		shift
	done

}

get_full_path() {

# This function finds the absolute path from a relative one.

	if [[ -f "$1" ]]; then					# A condition to check if using single file
		local filename="${1##*/}"			# Create a local variable for filename
		full_path="$(cd "${1%/*}" >/dev/null 2>&1 || exit; pwd -P)/${filename}"
	else
		# Change to the directory and get the parent directory
		full_path="$(cd "$1" >/dev/null 2>&1 || exit; pwd -P)"
	fi

	cd "${working_directory}" || exit		# Change back to the original working directory
	printf "%s\n" "${full_path%/}"			# Print out the full directory as well as trim trailing slash

}

# ========== Checking Functions ===========================================

check_dir() {

# Check if the input and output directory exist
# If they are not, it will print the usage message, error message and exit

	# If the output option is not specified, then create an "Output" folder
	# in the current working directory

	if [[ "$output_dir" == "null" ]]; then
		output_dir="${working_directory}/Output"
		mkdir -p "${output_dir}"
	fi

	# Trim off the slash at the end of the directories as they break the script
	input_dir="${input_dir%/}"
	output_dir="${output_dir%/}"

	# Find absolute paths for input and output
	cache_output_dir="${output_dir}"
	input_dir="$(get_full_path "${input_dir}")"
	output_dir="$(get_full_path "${output_dir}")"

	if [[ ! -d "$input_dir" ]]; then
		if [[ -f "$input_dir" ]]; then
			single_file="true"
		else
			usage "print"
			printf "%s\n\n" "${error} Input directory is not a valid directory"
			exit 3
		fi
	fi

	if [[ ! -d "$output_dir" ]]; then
		printf "\n%s" "${warning} Output directory is not a valid directory"
		printf "\n%s" "${warning} Do you want to create the output directory? [${yn}] "
		read -r a
		if [[ "$a" =~ ^[Yy]$ ]]; then
			if [[ "$output_dir" == "null" ]]; then
				output_dir="${working_directory}/Output"
			else
				output_dir="${working_directory}/${cache_output_dir}"
			fi
			mkdir -p "${output_dir}"
			printf "\n"
		else
			printf "\n%s\n\n" "${error} Exiting..."
			exit 3
		fi
	fi

}

check_app() {

# Check if the program exist, if not then it will state that it is not installed
# and exit the script.

	# Check bash version
	bash_version="${BASH_VERSION/(*}"
	bash_version="${bash_version//./ }"

	local major minor
	read -r major minor < <(awk '{ print $1, $2 }' <<< "${bash_version}")

	if ((minor < 4)) || ((major < 4)); then
		printf "%s\n" "${error} Bash 4.4+ is required. Your current bash version is ${BASH_VERSION}."
		printf "%s\n\n" "${error} Exiting..."
		exit 5
	fi
	
	# If p7z is not installed, the script will fallback to unzip instead. However,
	# due to how some comic archives are compressed, unzip might not be able to 
	# extract those files, thus why p7z is used

	if type -p 7z >/dev/null 2>&1; then
		extractor="7z"
	fi
	if [[ -z "$extractor" ]] && type -p 7za >/dev/null 2>&1; then
		extractor="7za"
	fi
	if [[ -z "$extractor" ]] && type -p unzip >/dev/null 2>&1; then
		extractor="unzip"
	fi
	if type -p convert >/dev/null 2>&1; then
		useConvert="true"
	fi

	# Print verbose information
	if [[ "$verbose" == "true" ]]; then
		printf "%s\n" "${green}${bold}Extractor${reset}:	${extractor}"
		printf "%s\n\n" "${green}${bold}Bash version${reset}: 	${BASH_VERSION}"
	fi

	case "$extractor" in
		unzip)	printf "%s\n" "${warning} 7z is not installed, falling back to Unzip" ;;
		"")		printf "%s\n" "${error} Unzip and 7z is not installed."
				printf "%s\n\n" "${error} Exiting..."
				exit 4 ;;
	esac

	if [[ "$useConvert" != "true" ]]; then
		printf "%s\n" "${error} ImageMagick is not installed."
		printf "%s\n\n" "${error} Exiting..."
		exit 4
	fi

}

check_log_level() {

	local check=$1
	case "1:${check:--}" in
		("$((check >= 4))"*)		log_level=4; set -x ;;
		("$((check == 3))"*)		log_level=3; verbose="true"; quiet="false" ;;
		("$((check == 2))"*|"")		log_level=2; verbose="false"; quiet="false" ;;
		("$((check == 1))"*)		log_level=1; verbose="false"; quiet="false" ;;
		("$((check == 0))"*)		unset log_level; verbose="false"; quiet="true" ;;
	esac

}

# ========== Main Functions ===============================================

extract() {

# This section extract files through the parsed arguments.

	print_log "extract" "message"

	# Assign parsed options into one string for case to parse easily
	local cmd="${extractor} ${verbose:0:1} ${quiet:0:1} ${skip_spinner:0:1}"
	case "$cmd" in
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

check_folder() {

# Sometimes, the images are within a folder after extraction
# This detects if there is a subfolder after extraction and
# moves the files up one level

	local -r check="$(find "$1" -type d -maxdepth 2 | awk 'NR==2{print;exit}')"

	if [[ -z "$check" ]]; then
		print_log "check_folder" "false"
	else
		print_log "check_folder" "true"
		if [[ "$verbose" == "true" ]]; then
			mv -v "${check}"/* "$1"
		else
			mv "${check}"/* "$1"
		fi
		rmdir "${check}"
	fi

}

check_if_exist() {

	if [[ ! -f "$1" || $overwrite == "true" ]]; then
		[[ -f "$1" ]] && rm -f "$1"
		return 0
	else
		existed+=("${1}")
		return 1
	fi

}

check_extension() {

# Conversion will fail if the file extension does not
# match due to a difference in case. This function
# will individually check each extracted images to
# ensure that they are all lowercase.

	print_log "check_extension" "message"

	while read -r check; do

		local file="${check##*/}"
		local filename="${file%.*}"				# Get filename
		local file_ext="${file##*.}"			# Get file extension

		# Condition to check if the file extension is already lowercase
		if [[ "$file_ext" == "jpg" || "$file_ext" == "png" ]]; then
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

	# Print appropriate message for checking extension case
	case "$return_code" in
		0) print_log "check_extension" "false" ;;
		1) print_log "check_extension" "true" ;;
	esac

}

convert_file() {

# Convert .jpg to .pdf

	# Exit if extract flag is set to true
	[[ "$extract" == "true" ]] && return 0

	print_log "convert" "message"

	# Assign parsed options into one string for case to parse easily
	local cmd="${verbose:0:1} ${quiet:0:1} ${skip_spinner:0:1}"
	case "$cmd" in
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

	[[ "$extract" == "true" || "$keep_file" == "true" ]] && return 0

	print_log "delete" "message"

	if [[ "$verbose" == "true" ]]; then
		rm -rfv "$1"
	else
		rm -rf "$1"
	fi

}

check_completed() {

# This function determines if the converting succeeded.
# If it did, then add the filename to the array of completed.
# If it didn't, then add the filename to the array of incomplete.
# This section is skipped if parallel is on.

	if [[ "$parallel" != "true" ]]; then
		if [[ "$extract" == "true" ]]; then
			if [[ ! -z "$(find "${output_filename}" -type f)" ]]; then
				able_to_convert+=("${input_file}")
				print_log "extract" "success"
			else
				fail_to_convert+=("${input_file}")
				print_log "extract" "fail"
			fi
		else
			if [[ -f "${output_filename}.pdf" ]]; then
				able_to_convert+=("${input_file}")
				print_log "convert" "success"
			else
				fail_to_convert+=("${input_file}")
				print_log "convert" "fail"
			fi
		fi
		# Increment job counter
		((++count))
	fi

}

parallel_process_files() {

# This function sets up the parallelisation process

	if [[ "$extract" == "true" ]]; then
		print_log "extract" "parallel_message"
	else
		print_log "convert" "parallel_message"
	fi

	process_files "$(printf "%s\n" "${group_1[@]}")" >/dev/null 2>&1 &
	
	if ((p_amount > 0)); then
		process_files "$(printf "%s\n" "${group_2[@]}")" >/dev/null 2>&1 &
		if ((p_amount == 4)); then
			process_files "$(printf "%s\n" "${group_3[@]}")" >/dev/null 2>&1 &
			process_files "$(printf "%s\n" "${group_4[@]}")" >/dev/null 2>&1 &
		fi
	fi

	[[ "$skip_spinner" != "true" ]] && spinner

	wait
	printf "\n\n"

}

process_files() {

# This is the main processing function where the file is
# extracted and converted.

	local array=("$@")
	while read -r input_file; do	
		local parent_dir="${input_dir%/*}"							# Get parent directory
		local source_dir="${input_file%/*}"							# Get the source directory
		local source_file="${input_file##*/}"						# Get the source filename
		local source_filename="${source_file%.*}"					# Format the source filename
		local source_ext="${source_file##*.}"						# Get the source file extension
		# Check if converting one file
		[[ "$single_file" != "true" ]] && local output_file="${source_dir#$parent_dir}"
		local output_file="${output_dir}${output_file}"				# Format the destination directory
		local output_filename="${output_file}/${source_filename}"

		# Check if the converted file is already completed
		if check_if_exist "${output_filename}.pdf"; then

			# Make the output folder
			mkdir -p "${output_file}"

			# Print file and directory information
			print_file_info

			# Make output for converting
			mkdir -p "${output_filename}"

			# Print specific info if log_level = 1
			print_log "before"

			# Extract, check, convert and delete
			extract "${input_file}" "${output_filename}"
			check_folder "${output_filename}"
			check_extension "${output_filename}"
			convert_file "${output_filename}/*.{jpg,png}" "${output_filename}.pdf"
			delete "${output_filename}"

			# Print specific info if log_level = 1
			print_log "after"

			# Check the completed files
			check_completed

		else

			print_file_info
			print_log "skip"
			((++count))

		fi

	done < <(printf "%s\n" "${array[@]}")

}

init_process() {

# This function determines if the parallelisation flag
# is on, and then selects the appropriate function.

	IFS=$'\n'
	if [[ "$parallel" == "true" ]]; then
		parallel_process_files
	else
		process_files "$(printf "%s\n" "${file_list_input[@]}")"
	fi
	IFS="${old_ifs}"
	print_summary

}

main() {

	trap "exit 1" INT
	get_args "$@"
	check_log_level "${log_level}"
	print_verbose
	check_dir
	check_app

	get_file_list
	print_file_list

	split_list
	init_process

}

# ========== Start Script ====================================================

main "$@"