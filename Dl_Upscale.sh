#!/bin/bash

# Détecter le chemin du répertoire du script
URL=$(cat url.txt)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Script exécuté à : $(date)"

# Fonction de nettoyage
cleanup() {
    echo "Nettoyage des répertoires temporaires..."
    rm -rf "$BASE_DIR/inOP$CHAPTER_NUMBER" "$BASE_DIR/outOP$CHAPTER_NUMBER"
    echo "Nettoyage terminé."
}

# Définir le piège pour les signaux INT (Ctrl+C) et TERM (kill)
trap cleanup INT TERM

# Vérifiez si les arguments sont fournis
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <chapter_number> <scale_factor>"
    exit 1
fi
source OpVenv/bin/activate
CHAPTER_NUMBER=$1
SCALE_FACTOR=$2

echo "Numero du chapitre : $CHAPTER_NUMBER"
echo "Facteur d'échelle : $SCALE_FACTOR"

mkdir -p "$BASE_DIR/inOP$CHAPTER_NUMBER"

cd "$BASE_DIR/inOP$CHAPTER_NUMBER"

echo "Downloading ..."

# Télécharger et extraire
wget "$URL$CHAPTER_NUMBER" -O "OP$CHAPTER_NUMBER" --max-threads --waitretry
unzip -x "OP$CHAPTER_NUMBER" && rm "OP$CHAPTER_NUMBER"

sleep 1

# Revenir au répertoire précédent
cd "$BASE_DIR"

# Créer le répertoire de sortie
mkdir -p "$BASE_DIR/outOP$CHAPTER_NUMBER"

# Upscale
"$BASE_DIR/realesrgan-ncnn-vulkan" -i "$BASE_DIR/inOP$CHAPTER_NUMBER/" -o "$BASE_DIR/outOP$CHAPTER_NUMBER" -n realesr-animevideov3 -s $SCALE_FACTOR -f png -t -v

echo " upscale ended..."
sleep 2

# Supprimer le répertoire d'entrée
rm -r "$BASE_DIR/inOP$CHAPTER_NUMBER"

echo "merging ..."

# Conversion des images en PDF
python "$BASE_DIR/img-pdf-convert" -i "$BASE_DIR/outOP$CHAPTER_NUMBER/*.png" -o "$BASE_DIR/outOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER.pdf"

mv "$BASE_DIR/outOP$CHAPTER_NUMBER/OP$CHAPTER_NUMBER.pdf" "$BASE_DIR" && rm -r "$BASE_DIR/outOP$CHAPTER_NUMBER"

echo "cleanup ..."
# Nettoyage final au cas où
cleanup

echo "Script terminé à : $(date)"
