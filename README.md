# cbr2pdf
cbr2pdf is a bash script will convert all .cbr and .cbz files recursively from a folder to PDF files in a seperate folder with pretty text and stats. This script mainly uses ImageMagick to convert the images to pdf files and 7zip/p7z to extract the archives.

## Installation
### Git clone
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

## Usage
```sh
$ ./cbr2pdf.sh [-v|--verbose] [-i|--input "DIRECTORY"] [-o|--output "DIRECTORY"]
```

## Sample Output
```
┌[julian@Whirl]-(~)
└> ./cbr2pdf.sh -i input -o output

[Info] File information:

Job Number:             1/4
Parent Directory:       .
Source Directory:       input/(2010) The Transformers - Drift [#1-4]
Source File:            input/(2010) The Transformers - Drift [#1-4]/The Transformers - Drift 02.cbz
File Type:              cbz
Destination Directory:  output/input/(2010) The Transformers - Drift [#1-4]

[Info] Extracting archive...
[Info] No subfolders detected...
[Info] Converting to PDF...
[Info] Deleting extracted files...

[Info] Finish converting output/input/(2010) The Transformers - Drift [#1-4]/The Transformers - Drift 02.cbz
--------------------------------------------------------------------------------------------


[Info] File information:

Job Number:             2/4
Parent Directory:       .
Source Directory:       input/(2010) The Transformers - Drift [#1-4]
Source File:            input/(2010) The Transformers - Drift [#1-4]/The Transformers - Drift 03.cbz
File Type:              cbz
Destination Directory:  output/input/(2010) The Transformers - Drift [#1-4]

[Info] Extracting archive...
[Info] No subfolders detected...
[Info] Converting to PDF...
[Info] Deleting extracted files...

[Info] Finish converting output/input/(2010) The Transformers - Drift [#1-4]/The Transformers - Drift 03.cbz
--------------------------------------------------------------------------------------------


[Info] File information:

Job Number:             3/4
Parent Directory:       .
Source Directory:       input/(2010) The Transformers - Drift [#1-4]
Source File:            input/(2010) The Transformers - Drift [#1-4]/The Transformers - Drift 04.cbz
File Type:              cbz
Destination Directory:  output/input/(2010) The Transformers - Drift [#1-4]

[Info] Extracting archive...
[Info] No subfolders detected...
[Info] Converting to PDF...
[Info] Deleting extracted files...

[Info] Finish converting output/input/(2010) The Transformers - Drift [#1-4]/The Transformers - Drift 04.cbz
--------------------------------------------------------------------------------------------


[Info] File information:

Job Number:             4/4
Parent Directory:       .
Source Directory:       input/(2010) The Transformers - Drift [#1-4]
Source File:            input/(2010) The Transformers - Drift [#1-4]/The Transformers - Drift 01.cbz
File Type:              cbz
Destination Directory:  output/input/(2010) The Transformers - Drift [#1-4]

[Info] Extracting archive...
[Info] No subfolders detected...
[Info] Converting to PDF...
[Info] Deleting extracted files...

[Info] Finish converting output/input/(2010) The Transformers - Drift [#1-4]/The Transformers - Drift 01.cbz
--------------------------------------------------------------------------------------------

[Info] Finish converting all files

┌[julian@Whirl]-(~)
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
Firstly, the script will run the ```preRun``` function. This function will record the startup time, check the output directory and check if the dependencies are installed. If ```preRun``` finishes successfully, then the main function will run.

#### Setting Variables
Using the ```find``` command for all files and not directories, we are able to feed it into a while loop as a the variable ```inputFile```. This variable is then seperated into ```PRT_DIR```, ```SRC_DIR```, ```SRC_FILE```, ```SRC_FILENAME```, ```SRC_EXT```, ```DST_DIR```.

  * ```PRT_DIR```: Parent directory
  * ```SRC_DIR```: Source directory
  * ```SRC_FILE```: Source file
  * ```SRC_FILENAME```: Source filename
  * ```SRC_EXT```: Source file extension
  * ```DST_DIR```: Destination directory
  
By doing so, it makes it easier to form the folder structure on the output directory, as well as detecting file type for filtering out files that isnt ```.cbr``` or ```.cbz```.

#### Extracting Files
After setting the variables, we can now extract the files from the input directory into the output directory. ```7z``` is used for extracting because ```unzip``` is unable to extract rar archives. ```unzip``` however, is used as a fallback if ```7z``` is not present. The extract function uses the variables ```inputFile``` and ```DST_DIR/SRC_FILE``` and to extract the files into the output directory within a folder with the name as the ```inputFile```.

#### Checking for Subfolders
Sometimes, the images are within a folder after extraction. This detects if there is a subfolder after extraction and moves the files up one level by using the ```find``` command for any directories within a max depth of 2. If there is a subfolder within the extracted directory, then the ```find``` command will print out 2 lines, first is the output directory and the second is the subfolder itself. Using ```sed```, we can assign the variable ```check``` to the second line of the command. A simple check is then perform to see if the ```check``` variable is empty. If it is, then there's no subfolder and the script continues. If it isn't empty, then the files inside of the subfolder is brought up one level using ```mv```.

#### Converting
Just like in the extract function, we used ```convert``` inside of a function where we pass the arguments ```DST_DIR/SRC_FILE/*.{jpg,png}``` and ```DST_DIR/SRC_FILENAME.pdf```. The first variable is all images inside of the extracted folder and the second variable is the final converted file.

#### Deleting
After converting the files, the extracted folder is then deleted and then moved on the the next file.
