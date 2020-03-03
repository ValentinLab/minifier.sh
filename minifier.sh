#!/bin/dash

# -------------------------------------------------- #
# DISPLAY HELP                                       #
# -------------------------------------------------- #

# Print a message to explain how to use this script
# Parameters : none
help () {
    echo 'usage : ./minifier.sh [OPTION]... dir_source dir_dest

Minifies HTML and/or CSS files with :
  dir_source   path to the root directory of the website to be minified
  dir_dest     path to the root directory of the minified website
  
OPTIONS
  --help    show help and exit
  -v            displays the list of minified files; and for eachfile, its final and
                initial sizes, and its reductionpercentage
  -f            if the dir_dest file exists, its content isremoved without asking
                for confirmation of deletion
  --css         CSS files are minified
  --html        HTML files are minified
  if none of the 2 previous options is present, the HTML and CSSfiles are minified
  -t            tags_file the "white space" characters preceding and following the
                tags (opening or closing) listed in the "tags_file" are deleted'
}

# Test if the --help argument is alone
# Parameters : The string composed by all the parameters of the script's call
helpTest () {
  if [ $# -eq 1 ]  && [ $1 = "--help" ]; then
    help
    exit 0
  fi
}

helpTest $@

# -------------------------------------------------- #
# CHECK ARGUMENTS                                    #
# -------------------------------------------------- #

HELP_MSG='Enter "./minifier.sh --help" for more information.'

# Test if the option are given only once as script's parameter; if not exit the program
# Parameters : The script's parameters to test
optionTestUnique () {
  if [ -z $1 ]; then
    return 0
  else
    echo "ERROR : The options must be unique\n$HELP_MSG"
    exit 1
  fi
}

# Test if the tags file can be modifiable (write and read) by the user,
# then store its content in a variable
# Parameters : none
tagFileTest () {
  if ! [ -f $ARG_TAG ] || ! [ -r $ARG_TAG ] || ! [ -w $ARG_TAG ]; then 
    echo "The tags file must be a modifiable text file.\n$HELP_MSG"
    exit 2
  fi 
  TAGS=$(cat $ARG_TAG) 
}

# Test if the tags file if given after the -t option
# Parameters : none
tagsFileExist () {
  if ! [ -z $ARG_T ] && [ -z $ARG_TAG ]; then 
    echo "The -t option must be followed by a path to an existing text file\n$HELP_MSG" 
    exit 5
  fi
}

# Test if both source and destination are specified and are different
# Parameters : none
pathsTest () {
  if [ -z $ARG_SRC ] || [ -z $ARG_DEST ]; then
    echo "Paths to 'dir_source' and 'dir_dest' directories must be specified\n$HELP_MSG"
    exit 6
  else 
    if [ $ARG_SRC = $ARG_DEST ]; then
      echo "'The paths dir_source' and 'dir_dest' must be different.\n$HELP_MSG"
      exit 7
    fi
  fi
}

# Ask the user to confirm that an already existing destination is to overwrite
# Parameters : none
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
    rm -rf $ARG_DEST
  fi
}

# -------------------------------------------------- #
# Main Arguments' validity test                      #
# -------------------------------------------------- #
ARG_SRC=''
ARG_DEST=''
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
            tagFileTest 
          elif  [ -z $ARG_SRC ]; then
            if [ -f $I ]; then
              echo "The source must be a directory\n$HELP_MSG"
              exit 3
            fi
            ARG_SRC=${I#*./}
            echo $ARG_SRC  
          else
            ARG_DEST=${I#*./}
            DEST_EXISTS=true
          fi
        else
          if [ -z $ARG_SRC ]; then 
            echo "The source must be an existing file\n$HELP_MSG"
            exit 4
          elif [ -z $ARG_DEST ]; then
            ARG_DEST=${I#*./}
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

# If none of the --css and --html arguments are passed, both types must be minified
if [ -z $ARG_CSS ] && [ -z $ARG_HTML ]; then 
  ARG_CSS=true
  ARG_HTML=true
fi
# -------------------------------------------------- #
# GET FILES                                          #
# -------------------------------------------------- #

# Get the extension of the parameters
# Parameters : One file
getType () {
  TYPE_FILE=$(basename $1)
  TYPE_FILE=${TYPE_FILE##*.}
}

# -------------------------------------------------- #
# VERBOSE                                            #
# -------------------------------------------------- #

# Compute the difference of size of the two files in parameters, then display 
# it with a message for the user
# Parameters : The 2 files to compare
getSize () {
  FIRST=$(stat --format=%s $1)
  SECOND=$(stat --format=%s $2)

  DIFFERENCE=$((100-$(($(($SECOND*100))/$FIRST))))

  echo "FILE $3 : $1 --> $SECOND / $FIRST : $DIFFERENCE %"
}

# -------------------------------------------------- #
# HTML MINIFIER                                      #
# -------------------------------------------------- #

# Minify the html file given in parameter
# Arguments : 1 html file
minifierHTML () {
  tr -s '\n' ' ' < $1 | perl -pe 's/<!--.*?-->//g' | sed -r 's/\r|\t|\v//g' > $2

  if ! [ -z $ARG_TAG ] ; then
    HTML_F=$(cat $2)
    for T in $TAGS ; do
      echo $HTML_F | sed -r -e "s/[ ]*<$T([^>]*)>[ ]*/<$T\1>/gI" -e "s/[ ]*<\/$T>[ ]*/<\/$T>/gI" > $2
    done
  fi

  if ! [ -z $ARG_V  ] ; then
    getSize $1 $2 HTML
  fi
}

# -------------------------------------------------- #
# CSS MINIFIER                                       #
# -------------------------------------------------- #

# Minify the css file given in parameter
# Arguments : 1 css file
minifierCSS () {
  tr -s '\n' ' ' < $1 | perl -pe 's/\/\*.*?\*\///g' | sed -r -e 's/\r|\t|\v//g' -e 's/[ ]*(:|;|,|\{|\}|>)[ ]*/\1/g' > $2

  if ! [ -z $ARG_V ] ; then
    getSize $1 $2 CSS
  fi
}

# -------------------------------------------------- #
# Creation of the destination's folder tree          #
# -------------------------------------------------- #

# Create recursively the tree structure for the destination folder, 
# then minify the html and css files in it
# Parameters : none
createDestDir () {
  local CONTENT=${1%*/}/*
  for I in $CONTENT; do 

    if [ -d $I ]; then 
      createDestDir $I
    else 
      getType $I
      if [ -n "$ARG_CSS" ]; then
        if [ $TYPE_FILE = 'css' ]; then
          minifierCSS $ARG_SRC/${I#*/} $I
        fi  
      fi
      if [ -n "$ARG_HTML" ]; then
        if [ $TYPE_FILE = 'html' ]; then
          minifierHTML $ARG_SRC/${I#*/} $I
        fi
      fi
    fi
  done
}

# -------------------------------------------------- #
# MINIFIER                                           #
# -------------------------------------------------- #
cp -r $ARG_SRC $ARG_DEST
createDestDir $ARG_DEST