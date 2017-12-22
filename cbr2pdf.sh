#!/usr/bin/env bash
# shellcheck disable=SC1117
# shellcheck disable=SC2059

# ========== Formating ====================================================
# This section delclares all of the text formatting required when printing
# information like color codes and linebreakss.

green=$'\e[32m'
red=$'\e[31m'
yellow=$'\e[33m'
reset=$'\033[0m'
underline=$'\e[4m'
bold=$'\e[1m'
line="$(printf '=%.0s' {1..48})"

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

export {verbose,extract,help,keep_file,quiet,single_file}="false"
export {parallel,skip_spinner,skip_summary,skip_list,useConvert}="false"

export {input_dir,output_dir}="null"
export {p_amount,total,count}=0

file_list_input=()
file_list_sort=()
fail_to_convert=()
able_to_convert=()
incompatible=()

old_ifs="${IFS}"
version="2.4"
working_directory="$(pwd)"

# ========== Printing Functions ===========================================

prin() {

# This function will only print arguments unless the quiet option
# is enabled

	if [[ "$quiet" == "true" ]]; then
		return 1
	fi

	printf "$@"

}

print_if_verbose() {

# Print a new line if verbose is enabled

	if [[ "$verbose" == "true" ]]; then
		prin "\n%s\n" "${line}"
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

print_header() {

# Prints header information

	case $1 in
		info)	prin "%s\n%s\n%s\n" "${line}" "${info} ${2}" "${line}" ;;
		warn)	prin "%s\n%s\n%s\n" "${line}" "${warning} ${2}" "${line}" ;;
		error)	prin "%s\n%s\n%s\n" "${line}" "${error} ${2}" "${line}" ;;
	esac

}

print_file_info() { 

# This section prints out the file information using the pre-defined
# color codes and formatting.

	print_header info "File information"
	
	prin "%s\n" "${green}${bold}Job Number${reset}:		${count}/${total}"
	prin "%s\n" "${green}${bold}Output Directory${reset}:	${output_file}"
	if [[ "$verbose" == "true" ]]; then
		prin "%s\n" "${green}${bold}Parent Directory${reset}:	${parent_dir}"
		prin "%s\n" "${green}${bold}Source Directory${reset}:	${source_dir}"
		prin "%s\n" "${green}${bold}File Type${reset}:		${source_ext}"
	fi
	prin "%s\n\n" "${green}${bold}Source File${reset}:		${input_file}"

}

print_file_list() {

# This function prints out the list of files to convert

	if [[ "$skip_list" == "true" ]]; then
		return 0
	fi

	print_header info "File list"

	if [[ "$parallel" != "true" ]]; then
		prin "%s\n" "${file_list_input[@]}"
		printf "\n"
	fi

}

print_split_list() {

# This function prints out the list of files to convert after
# the input list has been seperated into 4 groups

	if [[ "$skip_list" == "true" ]]; then
		return 0
	fi

	prin "%s\n%s\n" "${green}${bold}Group 1:${reset}" "${group_1[@]}"
	printf "\n"

	if [[ ${#group_2[@]} -gt 0 ]]; then
		prin "%s\n%s\n" "${green}${bold}Group 2${reset}:" "${group_2[@]}"
		printf "\n"

		if [[ ${#group_3[@]} -gt 0 ]]; then
			prin "%s\n%s\n" "${green}${bold}Group 3${reset}:" "${group_3[@]}"
			printf "\n"
	
			if [[ ${#group_4[@]} -gt 0 ]]; then
			prin "%s\n%s\n" "${green}${bold}Group 4${reset}:" "${group_4[@]}"
			fi
		fi
	fi

}

print_summary() {

# This section prints out the conversion summary after
# all files have been processed

	if [[ "$parallel" != "true" ]]; then
		if [[ "$skip_summary" != "true" ]]; then

			print_header info "Completed files"
			prin "%s\n" "${able_to_convert[@]}"
			printf "\n"
	
			if [[ ${#incompatible[@]} -gt 0 ]]; then
				print_header warn "Incompatible files"
				prin "%s\n" "${incompatible[@]}"
				printf "\n"
			fi
	
		fi

		if [[ ${#fail_to_convert[@]} -gt 0 ]]; then
			print_header error "Failed to convert ${#fail_to_convert[@]} files"
			prin "%s\n" "${fail_to_convert[@]}"
			printf "\n"
		fi
	fi

	if [[ "$extract" != true ]]; then
		print_header info "Finish converting all files"
	else
		print_header info "Finish extracting all files"
	fi

}

# ========== Eye Candy ====================================================

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

	case $1 in
		print_error)
				prin "%s\n\n" "${error} Unknown option: ${arg}"
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
		if [[ "${file_ext,,}" == "cbr" ]] || [[ "${file_ext,,}" == "cbz" ]]; then
			file_list_input+=("${i}")	# Add file path to array
		else
			incompatible+=("${i}")		# Record in incompatible files
		fi

	done < <(find "${input_dir}" -type f)

	# Sort array
	IFS=$'\n' file_list_sort=("$(sort <<<"${file_list_input[*]}")")
	IFS="${old_ifs}"

	unset file_list_input
	while read -r i; do
		file_list_input+=("${i}")
	done < <(printf "%s\n" "${file_list_sort[@]}")
	unset file_list_sort

	# Determine if input directory is empty
	if [[ -z "${file_list_input[*]}" ]]; then
		usage print
		printf "%s\n\n" "${error} Input directory is empty"
		exit 4
	fi

}

split_list(){

# This function is for parallelisation
# Parallisation is hard coded to have 4 split groups
# at the moment. It is preferable for the number of
# parallelisation processes to be user set. But at the
# moment I can't find a way to implement that function.

	# Skip function if parallel flag is not set
	if [[ "$parallel" != "true" ]]; then
		return 0
	fi

	case 1:${p_amount:--} in 
		($((p_amount >= 4))*)		p_amount=4 ;;
		($((p_amount >= 2))*|"")	p_amount=2 ;;
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
		usage print
		printf "%s\n\n" "${error} No options specified"
		exit 2
	fi

	while [[ "$#" -gt 0 ]]; do
		case "$1" in
			"-v"|"--verbose")	verbose="true"; quiet="false" ;;
			"-x"|"--extract")	extract="true" ;;
			"-h"|"--help")		usage ;;
			"-k"|"--keep")		keep_file="true" ;;
			"-q"|"--quiet")		quiet="true"; verbose="false" ;;
			"-p"|"--parallel")	parallel="true"; p_amount="$2"; shift ;;	
			"-i"|"--input")		input_dir="$2"; shift ;;
			"-o"|"--output")	output_dir="$2"; shift ;;
			"--version")		version ;;
			"--no-spinner")		skip_spinner="true" ;;
			"--no-summary")		skip_summary="true" ;;
			"--no-color")		reset_colors ;;
			"--no-list")		skip_list="true" ;; 
	    	-*|*)				arg="$1"; usage print_error ;;
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

	# Trim off the slash at the end of the directories as they break the script
	input_dir="${input_dir%/}"
	output_dir="${output_dir%/}"

	# Find absolute paths for input and output
	cache_output_dir="${output_dir}"
	input_dir="$(get_full_path "${input_dir}")"
	output_dir="$(get_full_path "${output_dir}")"

	# If the output option is not specified, then create an "Output" folder
	# in the current working directory

	if [[ "$output_dir" == "null" ]]; then
		output_dir="${working_directory}/Output"
		mkdir -p "${output_dir}"
	fi


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
		printf "\n%s\n" "${warning} Output directory is not a valid directory"
		printf "%s" "${warning} Do you want to create the output directory? [${yn}] "
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

	# Print verbose information
	if [[ "$verbose" == "true" ]]; then
		prin "%s\n" "${green}${bold}Extractor${reset}:		${extractor}"
	fi

	case "$extractor" in
		unzip)	prin "%s\n" "${warning} 7z is not installed, falling back to Unzip" ;;
		"")		prin "%s\n" "${error} Unzip and 7z is not installed."
				prin "%s\n\n" "${error} Exiting..."
				exit 3 ;;
	esac

	if [[ "$useConvert" != "true" ]]; then
		prin "%s\n" "${error} ImageMagick is not installed."
		prin "%s\n\n" "${error} Exiting..."
		exit 3
	fi

}

# ========== Main Functions ===============================================

extract() {

# This section extract files through the parsed arguments.

	prin "%s" "${info} Extracting archive..." && print_if_verbose

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

	local check="$(find "$1" -type d -maxdepth 2 | awk 'NR==2{print;exit}')"

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

check_extension() {

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

	case "$return_code" in
		0)	prin "\r%s" "${info} Extension case matches..." && print_if_verbose ;;
		1)	prin "\r%s" "${info} Extension case not match, changing..." && print_if_verbose ;;
	esac

}

convert_file() {

# Convert .jpg to .pdf

	# Exit if extract flag is set to true
	if [[ "$extract" == "true" ]]; then
		return 0
	fi

	prin "\n%s" "${info} Converting to PDF..." && print_if_verbose

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

parallel_process_files() {

# This function sets up the parallelisation process

	if [[ "$extract" == "true" ]]; then
		prin "%s" "Extracting in parallel..."
	else
		prin "%s" "Converting in parallel..."
	fi

	process_files $(printf "%s\n" "${group_1[@]}") >/dev/null 2>&1 &
	
	if [[ "$p_amount" -gt 1 ]]; then
	process_files $(printf "%s\n" "${group_2[@]}") >/dev/null 2>&1 &
		if [[ "$p_amount" == 4 ]]; then
			process_files $(printf "%s\n" "${group_3[@]}") >/dev/null 2>&1 &
			process_files $(printf "%s\n" "${group_4[@]}") >/dev/null 2>&1 &
		fi
	fi

	if [[ "$skip_spinner" != "true" ]]; then
		spinner
	fi

	wait
	prin "\n\n"

}

process_files() {

# This is the main processing function where the file is
# extracted and converted.

	local array=("$@")
	while read -r input_file; do	
		local parent_dir="${input_dir%/*}"					# Get parent directory
		local source_dir="${input_file%/*}"					# Get the source directory
		local source_file="${input_file##*/}"				# Get the source filename
		local source_filename="${source_file%.*}"			# Format the source filename
		local source_ext="${source_file##*.}"				# Get the source file extension
		if [[ "$single_file" != "true" ]]; then				# Check if converting one file
			local output_file="${source_dir#$parent_dir}"	# Get destination directory
		fi
		local output_file="${output_dir}${output_file}"		# Format the destination directory
		local output_filename="${output_file}/${source_filename}"

		# Make the output folder
		mkdir -p "${output_file}"

		# Print file and directory information
		print_file_info

		# Make output directory
		mkdir -p "${output_filename}"

		# Extract, check, convert and delete
		extract "${input_file}" "${output_filename}"
		check_folder "${output_filename}"
		check_extension "${output_filename}"
		convert_file "${output_filename}/*.{jpg,png}" "${output_filename}.pdf"
		delete "${output_filename}"

		# Determine if the converting succeeded
		# If it did, then add the filename to the array of completed
		# If it didn't, then add the filename to the array of incomplete
		# This section is skipped if parallel is on
		if [[ "$parallel" != "true" ]]; then
			if [[ "$extract" == "true" ]]; then
				if [[ ! -z "$(find "${output_filename}" -type f)" ]]; then
					able_to_convert+=("${input_file}")
					prin "\n%s\n\n" "${info} Finish extracting \"${source_file}\""
				else
					fail_to_convert+=("${input_file}")
					prin "\n%s\n\n" "${error} Failed to extract \"${source_file}\""
				fi
			else
				if [[ -f "${output_filename}.pdf" ]]; then
					able_to_convert+=("${input_file}")
					prin "\n%s\n\n" "${info} Finish converting \"${source_file}\""
				else
					fail_to_convert+=("${input_file}")
					prin "\n%s\n\n" "${error} Failed to convert \"${source_file}\""
				fi
			fi
			# Increment job counter
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
}

get_counter() {

	# Get counter information
	total="${#file_list_input[@]}"
	count=1

}

main() {

	trap 'exit 1' INT
	get_args "$@"
	print_verbose
	check_dir
	check_app

	get_file_list
	print_file_list
	get_counter

	split_list
	init_process

	print_summary

}

# ========== Start Script ====================================================

main "$@"