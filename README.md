# cbr2pdf
cbr2pdf is a bash script will convert all .cbr and .cbz files recursively from a folder to PDF files in a seperate folder with pretty colors and stats. This script mainly uses ImageMagick to convert the images to pdf files and 7zip/p7z to extract the archives.

## Installation
### Git
```sh
$ git clone https://github.com/Julian-Heng/cbr2pdf.git
$ cd cbr2pdf
$ ./cbr2pdf.sh
```
### Curl
```sh
$ curl https://raw.githubusercontent.com/Julian-Heng/cbr2pdf/master/cbr2pdf.sh > cbr2pdf.sh
$ chmod +x cbr2pdf.sh
$ ./cbr2pdf.sh
```

## Dependencies
The main commands used in this script are ```7z``` and ```ImageMagick```, but also include commands from the [GNU Core Utils](https://en.wikipedia.org/wiki/List_of_GNU_Core_Utilities_commands) like ```date```, ```dirname```, ```basename``` and ```printf```. So do keep that in mind. But if you're just running Ubuntu, or Arch Linux or any kind if linux, you should be fine.

For MacOS, you'll need [homebrew](https://brew.sh/) to install imagemagick and 7zip. It will also install the Xcode Commandline tools, which includes ```git```. ```Curl``` is also not installed by default.

### Installing Dependencies
#### Ubuntu/Debian
```sh
$ sudo apt install p7zip-full imagemagick
```
#### Arch Linux/Antergos
 ```sh
 $ sudo pacman -S p7zip imagemagick
 ```
#### MacOS
```sh
$ brew install p7zip imagemagick
```

## Usage
```sh
$ ./cbr2pdf.sh [-v|--verbose] [-x|--extract] [-h|--help] [-i|--input "DIRECTORY"] [-o|--output "DIRECTORY"] [-d|--debug]
```

## Help Output
```
Usage:	./cbr2pdf.sh --option --option VALUE

	Options:

	[-v|--verbose]			Enable verbose output
	[-x|--extract]			Only extract files without converting
	[-h|--help]			Displays this message
	[-i|--input "DIRECTORY"]	The input path for the files
	[-o|--output "DIRECTORY"]	The output path for the converted files
	[-d|--debug]			Shows debug information

	This bash script convert all comic book archives with the
	file extension .cbr or .cbz recursively from a folder
	to PDF files in a seperate folder.

	This script mainly uses ImageMagick to convert the images
	to pdf files and 7zip/p7z to extract the archives.

[NOTE] Both folders must already exist before starting this script
```

## Sample Output
```
┌[julian@Julians-MacBook-Pro]-(~)
└> ./cbr2pdf.sh -i Input/ -o Output/
================================================
[Info] File information
================================================
Job Number:		1/4
Output Directory:	Output/Input
Source File:		Input/The Transformers - Drift 04 (of 04) (2010).cbz

[Info] Extracting archive...
[Info] No subfolders detected...
[Info] Converting to PDF...
[Info] Deleting extracted files...
[Info] Finish converting The Transformers - Drift 04 (of 04) (2010).cbz

================================================
[Info] File information
================================================
Job Number:		2/4
Output Directory:	Output/Input
Source File:		Input/The Transformers - Drift 01 (of 04) (2010).cbz

[Info] Extracting archive...
[Info] No subfolders detected...
[Info] Converting to PDF...
[Info] Deleting extracted files...
[Info] Finish converting The Transformers - Drift 01 (of 04) (2010).cbz

================================================
[Info] File information
================================================
Job Number:		3/4
Output Directory:	Output/Input
Source File:		Input/The Transformers - Drift 02 (of 04) (2010).cbz

[Info] Extracting archive...
[Info] No subfolders detected...
[Info] Converting to PDF...
[Info] Deleting extracted files...
[Info] Finish converting The Transformers - Drift 02 (of 04) (2010).cbz

================================================
[Info] File information
================================================
Job Number:		4/4
Output Directory:	Output/Input
Source File:		Input/The Transformers - Drift 03 (of 04) (2010).cbz

[Info] Extracting archive...
[Info] No subfolders detected...
[Info] Converting to PDF...
[Info] Deleting extracted files...
[Info] Finish converting The Transformers - Drift 03 (of 04) (2010).cbz

================================================
[Info] Finish converting all files
================================================

┌[julian@Julians-MacBook-Pro]-(~)
└>
```

## Process
### Simplified
Basically there are 6 steps that the script performs

  1. List all files within the ```input``` directory
  2. Create the same folder structure as the ```input``` directory
  3. Extract using ```7z``` or ```unzip``` to the ```output``` directory
  4. Convert using ImageMagick from all ```.jpg``` or ```.png``` to ```.pdf```
  5. Delete extracted files
  6. Loop until all files are done

### Advance
#### Prerun
Firstly, the script will go and run all the prechecks before running the main script. This involves getting all arguments, printing verbose and debug information, checking directories and checking applications before continuing.

#### Setting Variables
Using the ```find``` command for all files and not directories, we are able to feed it into a while loop as a the variable ```inputFile```. This variable is then seperated into ```parent```, ```source_dir```, ```source_file```, ```source_filename```, ```source_ext```, ```output```.

  * ```parent```: Parent directory
  * ```source_dir```: Source directory
  * ```source_file```: Source file
  * ```source_filename```: Source filename
  * ```source_ext```: Source file extension
  * ```output```: Destination directory
  
By doing so, it makes it easier to form the folder structure on the output directory, as well as detecting file type for filtering out files that isnt ```.cbr``` or ```.cbz```.

#### Extracting Files
After setting the variables, we can now extract the files from the input directory into the output directory. ```7z``` is used for extracting because ```unzip``` is unable to extract rar archives. ```unzip``` however, is used as a fallback if ```7z``` is not present. The extract function uses the variables ```inputFile``` and ```output/source_file``` and to extract the files into the output directory within a folder with the name as the ```inputFile```.

#### Checking for Subfolders
Sometimes, the images are within a folder after extraction. This detects if there is a subfolder after extraction and moves the files up one level by using the ```find``` command for any directories within a max depth of 2. If there is a subfolder within the extracted directory, then the ```find``` command will print out 2 lines, first is the output directory and the second is the subfolder itself. Using ```sed```, we can assign the variable ```check``` to the second line of the command. A simple check is then perform to see if the ```check``` variable is empty. If it is, then there's no subfolder and the script continues. If it isn't empty, then the files inside of the subfolder is brought up one level using ```mv```.

#### Converting
Just like in the extract function, we used ```convert``` inside of a function where we pass the arguments ```output/source_file/*.{jpg,png}``` and ```output/source_filename.pdf```. The first variable is all images inside of the extracted folder and the second variable is the final converted file.

#### Deleting
After converting the files, the extracted folder is then deleted and then moved on the the next file.
