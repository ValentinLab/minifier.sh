#!/bin/dash

# Exercice 3
# Minifier un fichier CSS
# Le chemin vers le fichier CSS correspond au premier argument

# Destination folder
DEST_FOLDER=result

# CSS minifier
tr -s '\n' ' ' < $1 | perl -pe 's/\/\*.*?\*\///g' | sed -r -e 's/\r|\t|\v//g' -e 's/[ ]*(:|;|,|\{|\}|>)[ ]*/\1/g' > $DEST_FOLDER/$1