#!/bin/dash

# -------------------------------------------------- #
# DISPLAY HELP                                       #
# -------------------------------------------------- #

#
# Test if the --help argument is alone
# then print a message to explain how to use this script
# Parameters: all the parameters of the script's call
#
showHelp () {
  if [ $# -eq 1 ] && [ "$1" = --help ]; then
    echo 'usage : ./minifier.sh [OPTION]... dir_source dir_dest

Minifies HTML and/or CSS files with :
  dir_source   path to the root directory of the website to be minified
  dir_dest     path to the root directory of the minified website
  
OPTIONS
  --help        show help and exit
  -v            displays the list of minified files; and for eachfile, its final and
                initial sizes, and its reductionpercentage
  -f            if the dir_dest file exists, its content isremoved without asking
                for confirmation of deletion
  --css         CSS files are minified
  --html        HTML files are minified
  --php         PHP files are minified
  if none of the 2 previous options is present, the HTML and CSSfiles are minified
  -t            tags_file the "white space" characters preceding and following the
                tags (opening or closing) listed in the "tags_file" are deleted'
    exit 0
  fi
}

showHelp $@

# -------------------------------------------------- #
# CHECK ARGUMENTS                                    #
# -------------------------------------------------- #

HELP_MSG='Enter "./minifier.sh --help" for more information.'

#
# Test if the option is given only once as script's parameter
# if not exit the program
# Parameters: a script call parameter
#
optionTestUnique () {
  # Test if the option is empty (not already set to true)
  if [ -z $1 ]; then
    return 0
  else
    echo "The options must be unique\n$HELP_MSG"
    exit 1
  fi
}

#
# Test if the tags file can be write and read
# the content is stored in a variable
# Parameters: none
#
tagFileTest () {
  if ! [ -f $ARG_TAG ] || ! [ -r $ARG_TAG ] || ! [ -w $ARG_TAG ]; then 
    echo "The tags file must be a modifiable text file.\n$HELP_MSG"
    exit 2
  fi 
  # Store the tags file's content in a variable
  TAGS=$(tr '\n' ' ' < $ARG_TAG)
}

#
# Test if the tags file is given after the -t option
# Parameters: none
#
tagsFileExist () {
  if ! [ -z $ARG_T ] && [ -z $ARG_TAG ]; then 
    echo "The -t option must be followed by a path to an existing text file\n$HELP_MSG" 
    exit 5
  fi
}

#
# Test if both source and destination are specified and are different
# Parameters: none
#
pathsTest () {
  if [ -z $ARG_SRC ] || [ -z $ARG_DEST ]; then
    echo "Paths to 'dir_source' and 'dir_dest' directories must be specified\n$HELP_MSG"
    exit 6
  elif [ $ARG_SRC = $ARG_DEST ]; then
    echo "'The paths dir_source' and 'dir_dest' must be different.\n$HELP_MSG"
    exit 7
  fi
}

#
# Ask the user to confirm that an already existing destination is to overwrite
# only if the -f option is not present
# Parameters: none
#
userConfirmDelete () {
  if ! [ -z $DEST_EXISTS ] && [ -z $ARG_F ]; then
    echo -n "Do you want to remove ’$ARG_DEST’ ? [y/n] "
    read OVERWRITE
    # Leave script if the answer is different from y
    if [ "$OVERWRITE" != y ]; then
      exit 0
    fi
  fi
  rm -rf $ARG_DEST
}

# -------------------------------------------------- #
# MAIN ARGUMENTS VALIDITY TEST                       #
# -------------------------------------------------- #

# Check all arguments
ARG_SRC=''
ARG_DEST=''
for I in $*; do
  case $I in
    # Verbose option
    '-v' )
      if optionTestUnique $ARG_V; then
        ARG_V=true
      fi
      ;;

      # Force option
    '-f' )
      if optionTestUnique $ARG_F; then
        ARG_F=true
      fi
      ;;

    # CSS minifier option
    '--css' )
      if optionTestUnique $ARG_CSS; then
        ARG_CSS=true
      fi
      ;;

    # HTML minifier option
    '--html' )
      if optionTestUnique $ARG_HTML; then
        ARG_HTML=true
      fi
      ;;

    # PHP minifier option
    '--php' )
      if optionTestUnique $ARG_PHP; then
        ARG_PHP=true
      fi
      ;;

    # Tags file option
    '-t' )
      if optionTestUnique $ARG_T; then
        ARG_T=true
      fi
      ;;

      # Other options: path file, not supported option
      * )
        if [ -e "$I" ]; then
          I=${I#./*}
          if ! [ -z $ARG_T ] && [ -z $ARG_TAG ]; then
            ARG_TAG=$I
            tagFileTest
          elif  [ -z $ARG_SRC ]; then
            if [ -f "$I" ]; then
              echo "The source must be a directory\n$HELP_MSG"
              exit 3
            fi
            ARG_SRC=${I%*/}
          else
            ARG_DEST=${I%*/}
            DEST_EXISTS=true
          fi
        else
          if [ -z $ARG_SRC ]; then 
            echo "The source must be an existing file\n$HELP_MSG"
            exit 4
          elif [ -z $ARG_DEST ]; then
            ARG_DEST=${I%*/}
          else
            echo "The '$I' option is not supported\n$HELP_MSG"
            exit 5
          fi
        fi
        ;;
    esac
done

tagsFileExist
pathsTest
userConfirmDelete

# If none of the --css, --html and --php arguments are passed, all types must be minified
if [ -z $ARG_CSS ] && [ -z $ARG_HTML ] && [ -z $ARG_PHP ]; then 
  ARG_CSS=true
  ARG_HTML=true
  ARG_PHP=true
fi

# -------------------------------------------------- #
# GET FILES                                          #
# -------------------------------------------------- #

#
# Get the extention of the file
# Parameters: a filename
#
getType () {
  TYPE_FILE=$(basename $1)
  TYPE_FILE=${TYPE_FILE##*.}
}

# -------------------------------------------------- #
# VERBOSE                                            #
# -------------------------------------------------- #

#
# Compute the difference of size of two files and display it
# Parameters: 2 filenames
#
getSize () {
  FIRST=$(stat --format=%s $1)
  SECOND=$(stat --format=%s $2)

  DIFFERENCE=$((100-$(($(($SECOND*100))/$FIRST))))

  echo "File $3 : $2 --> $SECOND / $FIRST : $DIFFERENCE %"
}

# -------------------------------------------------- #
# HTML MINIFIER                                      #
# -------------------------------------------------- #

#
# Remove html tags
# Parameters: html filename
#
removeTags () {
  if ! [ -z $ARG_TAG ] ; then
    for T in $TAGS ; do
      HTML_DATA=$(cat $1)
      echo $HTML_DATA | sed -r -e "s/[ ]*(<$T[^>]*>)[ ]*/\1/gI" -e "s/[ ]*(<\/$T>)[ ]*/\1/gI" > $1
    done
  fi
}

#
# Minify a html file
# Parameters: html filename
#
minifierHTML () {
  tr '\n' ' ' < $1 | tr -s ' ' | perl -pe 's/<!--.*?-->//g' | sed -r 's/\r|\t|\v//g' > $2

  # Use tags file if the option -t is set
  removeTags $2

  # Print size if the option -v is set
  if ! [ -z $ARG_V  ] ; then
    getSize $1 $2 HTML
  fi
}

# -------------------------------------------------- #
# CSS MINIFIER                                       #
# -------------------------------------------------- #

#
# Minify a css file
# Parameters: css filename
#
minifierCSS () {
  tr '\n' ' ' < $1 | tr -s ' ' | perl -pe 's/\/\*.*?\*\///g' | sed -r -e 's/\r|\t|\v//g' -e 's/[ ]*(:|;|,|\{|\}|>)[ ]*/\1/g' > $2

  # Print size if the option -v is set
  if ! [ -z $ARG_V ] ; then
    getSize $1 $2 CSS
  fi
}

# -------------------------------------------------- #
# PHP MINIFIER                                       #
# -------------------------------------------------- #

minifierPHP () {
  sed -r 's/^[ |\t]*\/\/.*//' $1 | tr '\n' ' ' | tr -s ' ' | perl -pe 's/<!--.*?-->//g' | perl -pe 's/\/\*.*?\/\*//g' | sed -r 's/\r|\t|\v//g' > $2

  # Php can contains html
  # Use tags file if the option -t is set
  removeTags $2

  # Print size if the option -v is set
  if ! [ -z $ARG_V ] ; then
    getSize $1 $2 PHP
  fi
}

# -------------------------------------------------- #
# MINIFIER                                           #
# -------------------------------------------------- #

#
# Minify html and css files in a directory
# Reproduce the source file tree
# Parameters: a directory name
#
minifyAll () {
  local CONTENT=$1/*
  
  for I in $CONTENT ; do
    DEST_FILE=$ARG_DEST/${I#$ARG_SRC/*}
    if [ -d $I ] ; then
      mkdir $DEST_FILE
      minifyAll $I
    else
      getType $I
      if ! [ -z $ARG_CSS ] && [ "$TYPE_FILE" = css ] ; then
        minifierCSS $I $DEST_FILE
      elif ! [ -z $ARG_HTML ] && [ "$TYPE_FILE" = html ] ; then
        minifierHTML $I $DEST_FILE
      elif ! [ -z $ARG_PHP ] && [ "$TYPE_FILE" = php ] ; then
        minifierPHP $I $DEST_FILE
      elif [ -f $I ] ; then
        cp $I $DEST_FILE
      fi
    fi
  done
}

mkdir $ARG_DEST
minifyAll $ARG_SRC
