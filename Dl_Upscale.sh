#!/bin/bash

URL=$(cat url.txt)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Script exécuté à : $(date)"

#Fucntion that cleanup the environement
cleanup() {
    echo "cleanup temporary files..."
    rm -rf "$BASE_DIR/inOP$CHAPTER_NUMBER" "$BASE_DIR/outOP$CHAPTER_NUMBER"
    echo "cleanup done !"
}

#in the case if the script is canceled
trap cleanup INT TERM

#if the user no enter parameter
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <chapter_number> <scale_factor(2 to 4)>"
    exit 1
fi

#enter inside the venv
source OpVenv/bin/activate

CHAPTER_NUMBER=$1
SCALE_FACTOR=$2

echo "Numero du chapitre : $CHAPTER_NUMBER"
echo "Facteur d'échelle : $SCALE_FACTOR"

mkdir -p "$BASE_DIR/inOP$CHAPTER_NUMBER"

cd "$BASE_DIR/inOP$CHAPTER_NUMBER"

echo "Downloading ..."

#here you need to adapt the code depending of your url
# -O mean output name of the downloaded archive
wget "$URL$CHAPTER_NUMBER" -O "OP$CHAPTER_NUMBER" --max-threads --waitretry

#unzip the archive
unzip -x "OP$CHAPTER_NUMBER" && rm "OP$CHAPTER_NUMBER"

sleep 1
cd "$BASE_DIR"

mkdir -p "$BASE_DIR/outOP$CHAPTER_NUMBER"

#upscale images
"$BASE_DIR/realesrgan-ncnn-vulkan" -i "$BASE_DIR/inOP$CHAPTER_NUMBER/" -o "$BASE_DIR/outOP$CHAPTER_NUMBER" -n realesr-animevideov3 -s $SCALE_FACTOR -f png -t -v

echo "upscale ended..."

sleep 2
clear >$(tty)

rm -r "$BASE_DIR/inOP$CHAPTER_NUMBER"

echo "merging ..."
#convert upscaled images into one PDF
python "$BASE_DIR/img-pdf-convert" -i "$BASE_DIR/outOP$CHAPTER_NUMBER/*.png" -o "$BASE_DIR/outOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER.pdf"

mv "$BASE_DIR/outOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER.pdf" "$BASE_DIR" && rm -r "$BASE_DIR/outOP$CHAPTER_NUMBER"

echo "cleanup ..."

cleanup

echo "runtime : $runtime"

echo "end : $(date)"
