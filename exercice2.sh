#!/bin/dash

# Exercice 2
# Minifier un fichier HTML
# Le chemin vers le fichier HTML correspond au premier argument

# Destination folder
DEST_FOLDER=result

# Get tags
TAGS=$(cat $2)

# HTML minifier
FILE=$(tr -s '\n' ' ' < $1 | perl -pe 's/<!--.*?-->//g' | sed -r 's/\r|\t|\v//g')
for T in $TAGS ; do
  FILE=$(echo $FILE | sed -r -e "s/[ ]*<$T([^>]*)>[ ]*/<$T\1>/gI" -e "s/[ ]*<\/$T>[ ]*/<\/$T>/gI")
done

echo $FILE > $DEST_FOLDER/$1
