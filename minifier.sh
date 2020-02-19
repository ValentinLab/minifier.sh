#!/bin/dash

HELP_MSG='Enter "./minifier.sh --help" for more information.'

# Print a message to explain how to use this script
help () {
  echo 'usage : ./minifier.sh [OPTION]... dir_source dir_dest\n
Minifies HTML and/or CSS files with :
    dir_source   path to the root directory of the website to be minified
    dir_dest     path to the root directory of the minified website
    OPTIONS
      --help       show help and exit
      -v           displays the list of minified files; and for eachfile, its final and initial sizes, and its reductionpercentage
      -f           if the dir_dest file exists, its content isremoved without asking for confirmation of deletion
      --css        CSS files are minified
      --html       HTML files are minified
    if none of the 2 previous options is present, the HTML and CSSfiles are minified
      -t tags_file the "white space" characters preceding and following the
        tags (opening or closing) listed in the "tags_file" are deleted'
}

# Test if the --help argument is alone
helpTest () {
  if [ $# -eq 1 ] && [ $1 = "--help" ]; then
    help
    exit 0
  fi
  exit 1
}

# Test if the option are given only once as script's parameter; if not exit the program
optionTestUnique () {
  if [ -z $1 ]; then
    return 0
  else
    echo "ERROR : The options must be unique\n$HELP_MSG "
    exit 2
  fi
}

# Test if the tags file can be write and read by the user
tagFileTest () {
  if ! [ -f $1 ] || ! [ -r $1 ] || ! [ -w $1 ]; then 
    echo "The tags file must be a modifiable text file.\n$HELP_MSG"
    exit 3
  fi 
  # Store the tags file's content in a variable
  TAGS=$(cat $ARG_TAG) 
}

# Test if the tags file if given after the -t option
tagsFileExist () {
  if ! [ -z $ARG_T ] && [ -z $ARG_TAG ]; then 
    echo "The -t option must be followed by a path to an existing text file\n$HELP_MSG" 
    exit 4
  fi
}

# Test if both source and destination are specified and are different
pathsTest () {
  if [ -z $ARG_SRC ] || [ -z $ARG_DEST ]; then
    echo "Paths to 'dir_source' and 'dir_dest' directories must be specified\n$HELP_MSG"
    exit 6
  elif [ $ARG_SRC = $ARG_DEST ]; then
    echo "'The paths dir_source' and 'dir_dest' must be different.\n$HELP_MSG"
    exit 5
  fi  
}

# Ask the user to confirm that an already existing destination is to overwrite
userConfirmDelete () {
  if ! [ -z $DEST_EXISTS ] && [ -z $ARG_F ]; then 
    OVERWRITE=0
    while [ $OVERWRITE != y ] && [ $OVERWRITE != n ]; do
      echo "$ARG_DEST already exists - Are you sure you want to overwrite it ? [y/n]"
      read OVERWRITE
    done
    if [ $OVERWRITE = n ]; then 
      exit 0
    fi
    ARG_F=true
  fi
}

ARG_SRC=''
ARG_DEST=''
# Test if the arguments are valid
for I in $*; do 
  case $I in 
    '-v' )
      optionTestUnique $ARG_V
      if [ $? -eq 0 ]; then
        ARG_V=true
      fi
      ;;

    '-f' )
      optionTestUnique $ARG_F
      if [ $? -eq 0 ]; then
        ARG_F=true
      fi
      ;;

    '--css' )
      optionTestUnique $ARG_CSS
      if [ $? -eq 0 ]; then
        ARG_CSS=true
      fi
      ;;

    '--html' )
      optionTestUnique $ARG_HTML
      if [ $? -eq 0 ]; then
        ARG_HTML=true
      fi
      ;;

    '-t' )
      optionTestUnique $ARG_T
      if [ $? -eq 0 ]; then
        ARG_T=true
      fi
    ;;

    * )
      if [ -e $I ]; then
        if ! [ -z $ARG_T ] && [ -z $ARG_TAG ]; then 
          ARG_TAG=$I
          tagFileTest $ARG_TAG
        elif [ -z $ARG_SRC ]; then
          ARG_SRC=$I
        else
          ARG_DEST=$I
          DEST_EXISTS=true
        fi
      else
        if [ -z $ARG_SRC ]; then 
          echo "The source must be an existing file\n$HELP_MSG"
          exit 6
        elif [ -z $ARG_DEST ]; then
          ARG_DEST=$I
        else
          echo "The '$I' option is not supported\n$HELP_MSG"
          exit 7
        fi
      fi
      ;;
  esac
done

helpTest $@

tagsFileExist

pathsTest

userConfirmDelete

echo "$ARG_CSS $ARG_F $ARG_T $ARG_SRC $ARG_DEST $TAGS"