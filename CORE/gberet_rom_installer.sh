#!/bin/bash

# Get the working directory
WORKING_DIRECTORY=$(pwd)
LENGTH=95

clear
echo " .-------------------------."
echo " |Building Green Beret ROMs|"
echo " '-------------------------'"

# Create necessary directories
mkdir -p "$WORKING_DIRECTORY/arcade/gberet"

echo "Copying Green Beret ROMs"
# Concatenate ROM files into binary output
cat "$WORKING_DIRECTORY/577l03.10c" "$WORKING_DIRECTORY/577l02.8c" > "$WORKING_DIRECTORY/arcade/gberet/rom1.bin"
cat "$WORKING_DIRECTORY/577l01.7c" "$WORKING_DIRECTORY/577l01.7c" > "$WORKING_DIRECTORY/arcade/gberet/rom2.bin"

echo "Copying Sprites"
cat "$WORKING_DIRECTORY/577l06.5e" "$WORKING_DIRECTORY/577l05.4e" "$WORKING_DIRECTORY/577l08.4f" "$WORKING_DIRECTORY/577l04.3e" > "$WORKING_DIRECTORY/arcade/gberet/sprites.bin"

echo "Copying Tiles"
cp "$WORKING_DIRECTORY/577l07.3f" "$WORKING_DIRECTORY/arcade/gberet/"

echo "Copying Sprite PROM"
cp "$WORKING_DIRECTORY/577h10.5f" "$WORKING_DIRECTORY/arcade/gberet/"

echo "Copying Character PROM"
cp "$WORKING_DIRECTORY/577h11.6f" "$WORKING_DIRECTORY/arcade/gberet/"

echo "Copying Palette PROM"
cp "$WORKING_DIRECTORY/577h09.2f" "$WORKING_DIRECTORY/arcade/gberet/"

echo "Generating blank config file"
# Create a blank file filled with 0xFF bytes
OUTPUT_FILE="$WORKING_DIRECTORY/arcade/gberet/gbcfg"
dd if=/dev/zero bs=1 count=$LENGTH | tr '\000' '\377' > "$OUTPUT_FILE"

echo "All done!"
