#!/bin/bash

URL=$(cat url.txt)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Script started at : $(date)"

# Function to clean up the environment
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$BASE_DIR/inOP$CHAPTER_NUMBER" "$BASE_DIR/outOP$CHAPTER_NUMBER"
    echo "Cleanup done!"
}

# Trap to handle script cancellation
trap cleanup INT TERM

# If the user doesn't provide necessary parameters
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <chapter_number> <scale_factor(2 to 4)>"
    exit 1
fi

# Record start time
start_time=$(date +%s)

# Activate virtual environment
source OpVenv/bin/activate

CHAPTER_NUMBER=$1
SCALE_FACTOR=$2

echo "Chapter number: $CHAPTER_NUMBER"
echo "Scale factor: $SCALE_FACTOR"

mkdir -p "$BASE_DIR/inOP$CHAPTER_NUMBER"
cd "$BASE_DIR/inOP$CHAPTER_NUMBER"

# Check if the URL file contains a link or a local archive path
if [[ "$URL" =~ ^https?:// ]]; then
    echo "Downloading..."
    wget "$URL$CHAPTER_NUMBER" -O "OP$CHAPTER_NUMBER.zip" --max-threads --waitretry

    # Check if the downloaded file is a valid ZIP
    if file "OP$CHAPTER_NUMBER.zip" | grep -q "Zip archive"; then
        echo "Valid ZIP file downloaded."
    else
        echo "Error: The downloaded file is not a valid ZIP."
        exit 1
    fi
elif [ -f "$URL" ]; then
    echo "Using local archive: $URL"
    cp "$URL" "OP$CHAPTER_NUMBER.zip"
else
    echo "The content of url.txt is neither a valid URL nor an existing local archive."
    exit 1
fi

# Unzip the archive
echo "Unzipping archive OP$CHAPTER_NUMBER.zip..."
unzip -x "OP$CHAPTER_NUMBER.zip" -d "OP$CHAPTER_NUMBER"
rm "OP$CHAPTER_NUMBER.zip"

# Check the extracted files
echo "Files extracted into OP$CHAPTER_NUMBER:"
ls "$BASE_DIR/inOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER"

# Adjust the path if an extra subfolder was created during extraction
if [ -d "$BASE_DIR/inOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER" ]; then
    IMAGE_DIR="$BASE_DIR/inOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER"
else
    IMAGE_DIR="$BASE_DIR/inOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER"
fi

echo "Image directory: $IMAGE_DIR"

sleep 1
cd "$BASE_DIR"

mkdir -p "$BASE_DIR/outOP$CHAPTER_NUMBER"

# Upscale images
"$BASE_DIR/realesrgan-ncnn-vulkan" -i "$IMAGE_DIR/" -o "$BASE_DIR/outOP$CHAPTER_NUMBER" -n realesr-animevideov3 -s $SCALE_FACTOR -f png -t -v

# Check the images in outOP directory
echo "Checking images in outOP$CHAPTER_NUMBER"
ls "$BASE_DIR/outOP$CHAPTER_NUMBER"

echo "Upscaling finished..."

sleep 1
# Clear the screen
clear >$(tty)

rm -r "$BASE_DIR/inOP$CHAPTER_NUMBER"

echo "Merging images into PDF..."

# Convert upscaled images into a single PDF
python "$BASE_DIR/img-pdf-convert" -i "$BASE_DIR/outOP$CHAPTER_NUMBER/*.png" -o "$BASE_DIR/outOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER.pdf"

# Check if the PDF was generated
if [ ! -f "$BASE_DIR/outOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER.pdf" ]; then
    echo "Error: PDF file was not generated."
    exit 1
fi

mv "$BASE_DIR/outOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER.pdf" "$BASE_DIR" && rm -r "$BASE_DIR/outOP$CHAPTER_NUMBER"

echo "Final cleanup..."

cleanup

# Record end time and calculate the duration
end_time=$(date +%s)
runtime=$((end_time - start_time))

echo "Runtime: $runtime seconds"

echo "End: $(date)"
