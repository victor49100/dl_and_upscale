#!/bin/bash

URL=$(cat url.txt)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Script exécuté à : $(date)"

# Fonction de nettoyage de l'environnement
cleanup() {
    echo "Nettoyage des fichiers temporaires..."
    rm -rf "$BASE_DIR/inChapter$CHAPTER_NUMBER" "$BASE_DIR/outChapter$CHAPTER_NUMBER"
    echo "Nettoyage terminé !"
}

# Gestion de l'annulation du script
trap cleanup INT TERM

# Si l'utilisateur n'entre pas les paramètres nécessaires
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <chapter_number> <scale_factor(2 to 4)>"
    exit 1
fi

# Activation de l'environnement virtuel
source ChapterVenv/bin/activate

CHAPTER_NUMBER=$1
SCALE_FACTOR=$2

echo "Numéro du chapitre : $CHAPTER_NUMBER"
echo "Facteur d'échelle : $SCALE_FACTOR"

mkdir -p "$BASE_DIR/inChapter$CHAPTER_NUMBER"
cd "$BASE_DIR/inChapter$CHAPTER_NUMBER"

# Vérification si le fichier url.txt contient un lien ou un chemin local
if [[ "$URL" =~ ^https?:// ]]; then
    echo "Téléchargement en cours..."
    wget "$URL$CHAPTER_NUMBER" -O "chapter$CHAPTER_NUMBER.zip" --max-threads --waitretry

    # Vérification si le fichier téléchargé est bien un ZIP
    if file "chapter$CHAPTER_NUMBER.zip" | grep -q "Zip archive"; then
        echo "Fichier ZIP valide téléchargé."
    else
        echo "Erreur : le fichier téléchargé n'est pas un ZIP valide."
        exit 1
    fi
elif [ -f "$URL" ]; then
    echo "Utilisation de l'archive locale : $URL"
    cp "$URL" "chapter$CHAPTER_NUMBER.zip"
else
    echo "Le contenu de url.txt n'est ni un lien valide ni un fichier d'archive local existant."
    exit 1
fi

# Décompression de l'archive
echo "Décompression de l'archive chapter$CHAPTER_NUMBER.zip..."
unzip -x "chapter$CHAPTER_NUMBER.zip" -d "chapter$CHAPTER_NUMBER"
rm "chapter$CHAPTER_NUMBER.zip"

# Vérification du contenu décompressé
echo "Fichiers extraits dans chapter$CHAPTER_NUMBER :"
ls "$BASE_DIR/inChapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER"

# Ajustement du chemin si un sous-dossier supplémentaire est créé
if [ -d "$BASE_DIR/inChapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER" ]; then
    IMAGE_DIR="$BASE_DIR/inChapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER"
else
    IMAGE_DIR="$BASE_DIR/inChapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER"
fi

echo "Chemin des images : $IMAGE_DIR"

sleep 1
cd "$BASE_DIR"

mkdir -p "$BASE_DIR/outChapter$CHAPTER_NUMBER"

# Upscaling des images
"$BASE_DIR/realesrgan-ncnn-vulkan" -i "$IMAGE_DIR/" -o "$BASE_DIR/outChapter$CHAPTER_NUMBER" -n realesr-animevideov3 -s $SCALE_FACTOR -f png -t -v

# Vérification des images dans le dossier outChapter
echo "Vérification des images dans outChapter$CHAPTER_NUMBER"
ls "$BASE_DIR/outChapter$CHAPTER_NUMBER"

echo "Upscaling terminé..."

sleep 1
# Nettoyage de l'écran
clear >$(tty)

rm -r "$BASE_DIR/inChapter$CHAPTER_NUMBER"

echo "Fusion des images..."

# Conversion des images upscalées en un seul fichier PDF
python "$BASE_DIR/img-pdf-convert" -i "$BASE_DIR/outChapter$CHAPTER_NUMBER/*.png" -o "$BASE_DIR/outChapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER.pdf"

# Vérification si le fichier PDF a été généré
if [ ! -f "$BASE_DIR/outChapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER.pdf" ]; then
    echo "Erreur : le fichier PDF n'a pas été généré."
    exit 1
fi

mv "$BASE_DIR/outChapter$CHAPTER_NUMBER/chapter$CHAPTER_NUMBER.pdf" "$BASE_DIR" && rm -r "$BASE_DIR/outChapter$CHAPTER_NUMBER"

echo "Nettoyage en cours..."

cleanup

echo "Durée d'exécution : $runtime"

echo "Fin : $(date)"
