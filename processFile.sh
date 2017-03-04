#!/bin/bash

echo "Processing file: $1"
newFile=$(echo $1 | sed s/\.doc/\.html/g)
echo "Intermediate HTML file will be: $newFile"
outputFile=$(echo "$(echo $1| cut -d' ' -f1).htm")

echo "Target output file is: $outputFile"

# Attempt to convert the target doc file to HTML
/Applications/LibreOffice.app/Contents/MacOS/soffice --headless --convert-to html:HTML "$1" 

# HTML Tidy the target file 
tidy -q -utf8 -wrap 1000 "$newFile" | tail -n +21 | grep -v "</html>" | grep -v "</body>" | grep -v "<body " | sed 's/http:\/\/www.tourette-london.ca\///g' > "$outputFile"

# Clean up intermediate file 
rm "$newFile"

# Add some whitespace before the embedded content
tidied=$(cat "$outputFile" | sed 's/\(.*\)/      \1/g')

# Strip out all of the font modifiers 
tidied=$(echo $tidied | sed -E 's/<font color="[^"]+">//g')
tidied=$(echo $tidied | sed -E 's/<font color= "[^"]+">//g')

# Strip out all of the paragraph classes
tidied=$(echo $tidied | sed -E 's/<p [^>]+>/<p>/g')

# Strip out all span classes
tidied=$(echo $tidied | sed -E 's/<span [^>]+>//g' | sed -E 's/<\/span>//g')

# Remove redundant hard breaks
tidied=$(echo $tidied | sed -E 's/<p><br><\/p>//g')

# Attempt to detect header and encode it properly
tidied=$(echo $tidied | sed -E 's/<p><font [^>]+>([^<]+)<\/font><\/p>/<h1>\1<\/h1>/g' | sed 's/<\/font>//g')

# Ensure anchors are not juxtaposed with words
tidied=$(echo $tidied | sed -E 's/<\/a>([a-zA-Z])/<\/a> \1/g' | sed 's/<\/a> s /<\/a>s /g')

# Remove "chronic</a></p> <p>" anomalies
tidied=$(echo $tidied | sed -E 's/chronic<\/a><\/p> <p>/chronic<\/a> /g')

# Splice article content together with header and footer
articleHead=$(cat articleHead.html)
articleFoot=$(cat articleFoot.html)
echo "$articleHead
 
$tidied
 
$articleFoot" > "$outputFile"

