#!/bin/sh

find ./.data ./.logs -type f \( -name "*.json" -o -name "*.log" -o -name "*.gz.b64" \) -exec rm -f {} +  