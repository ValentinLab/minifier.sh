# Minifier.sh : CLI minification tool

CLI minification tool fot HTML, CSS and PHP files.

## How to use it

 - Download/Clone the repository
 - Run the program with `./minifier.sh [OPTION]... dir_source dir_dest`

## Options

 - `--help` : show help and exit displays the list of minified files; and for eachfile, its final and initial sizes, and its reduction percentage
 - `-f` : if the dir_dest file exists, its content isremoved without asking for confirmation of deletion
 - `--css` : CSS files are minified
 - `--html` : HTML files are minified
 - `--php` : PHP files are minified

If none of the 2 previous options is present, the HTML and CSSfiles are minified
- `-t` : tags_file the "white space" characters preceding and following the tags (opening or closing) listed in the "tags_file" are deleted

## Required
 - [DASH](http://gondor.apana.org.au/~herbert/dash/)