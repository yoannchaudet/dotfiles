#!/usr/bin/env bash

# My email address
email="c.yoann@gmail.com"

# URL to fetch
url="https://github.com/yoannchaudet.keys"

# Output file
eval output_file="~/.gitAllowedSignersFile"

# Add content in the file
curl -s "$url" | while IFS= read -r line; do
    echo "$email $line"
done > "$output_file"
