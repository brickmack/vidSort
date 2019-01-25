# vidSort
Command line utility to list duration and title of all files in a directory. Useful for manual file de-duplication. Built around ffprobe

# Flags
  -s, -sa: sort by duration (ascending)
  
  -sd: sort by duration (descending)
  
  -m: only show files with matching durations
  
  -v: verbose
  
  -h: help

  Target directory must always be the first argument!

# Future plans:
  
  more supported extensions
  
  recursive mode
  
  matching with margin
    
Might reimplement in c or python later

# Changelog

## v1.1

*added help

*added verbose mode

*move argument checking before file checking, to catch bad arguments faster

*can put directory anywhere in the arguments, but only 1. Detect if multiple directories are given

*can give options as option name or flag

*minor text formatting fixes

*ascending and descending sort options

*exclude subfolders in find
