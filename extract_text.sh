#!/bin/bash

## From https://diging.atlassian.net/wiki/spaces/DCH/pages/5275668/Tutorial+Text+Extraction+and+OCR+with+Tesseract+and+ImageMagick?showComments=true&showCommentArea=true

BPATH=$1  # Path to directory containing PDFs.
OPATH=$2  # Path to output directory.
LANG=$3   # See man tesseract > LANGUAGES
MIN_WORDS=5     # Number of words required to accept pdftotext result.
if [ $(echo "$LANG" | wc -c ) -lt 1 ]   # Language defaults to eng.
    then
        LANG='eng'
fi
echo "language used: $LANG"
# If the output path does not exist, attempt to create it.
if [ ! -d "$OPATH" ]; then
    mkdir -p "$OPATH"
fi
for FILEPATH in $BPATH*.pdf; do
    # Extracts plain text content from a PDF.
    #
    # First, attempts to extract embedded text with pdftotext. If that fails,
    #  converts the PDF to TIFF and attempts to perform OCR with Tesseract.
    #
    # Path to text file to be created. E.g. ./myfile.txt
    OUTFILE=$OPATH$(basename $FILEPATH).txt
    touch "$OUTFILE"    # The text file will be created regardless of whether
                        #  text is successfully extracted.
    # First attempt ot use pdftotext to extract embedded text.
    echo -n "Attempting pdftotext extraction..."
    pdftotext "$FILEPATH" "$OUTFILE"
    FILESIZE=$(wc -w < "$OUTFILE")
    echo "extracted $FILESIZE words."
    # If that fails, try Tesseract.
    if [[ $FILESIZE -lt $MIN_WORDS ]]
        then
            #rm "$OUTFILE"
            echo -n "Attempting OCR extraction..."
            # Use imagemagick to convert the PDF to a high-rest multi-page TIFF.
            convert -density 300 "$FILEPATH" -depth 8 -strip -background white -alpha off ./temp.tiff > /dev/null 2>&1
            # Then use Tesseract to perform OCR on the tiff.
            tesseract ./temp.tiff "$OUTFILE" -l $LANG > /dev/null 2>&1
            # We don't need then intermediate TIFF file, so discard it.
            rm ./temp.tiff
            TEXT=".txt"
            FILESIZE=$(wc -w < "$OUTFILE$TEXT")
            #rm "$OUTFILE"
            echo "extracted $FILESIZE words."
    fi
done