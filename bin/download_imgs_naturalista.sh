#!/bin/bash

# Check if the input file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

input_file="$1"

# Read the input file line by line
while IFS=$'\t' read -r file_name url; do
  # Download the image and save it with the specified file name
  curl -o "$file_name" "$url"
done < "$input_file"