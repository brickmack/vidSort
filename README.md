# vidSort
Command line utility to list duration and title of all files in a directory. Useful for manual file de-duplication. Built around ffprobe

# Usage

  Usage: ./vidSort.sh [FILE] ... [OPTION]

  -s, -sa: sort by duration (ascending)
  
  -sd: sort by duration (descending)
  
  -m: only show files with matching durations
  
  -v: verbose
  
  -h: help

  Any other arguments, excluding those starting with - or -- (which will be treated as flags, and raise an error if invalid), are assumed to be directories. Multiple directories can be specified (though the output does not currently display the directory of each file). At least one target directory must be specified

# Future plans:
  
  recursive mode
  
  matching with margin
    
  Might reimplement in c or python later

# Changelog

## v1.2

* Added support for more file formats

* Can now support multiple directories

## v1.1

* Added help

* Added verbose mode

* Move argument checking before file checking, to catch bad arguments faster

* Can put directory anywhere in the arguments, but only 1. Detect if multiple directories are given

* Can give options as option name or flag

* Minor text formatting fixes

* Ascending and descending sort options

* Exclude subfolders in find

## v1.0

* Initial release