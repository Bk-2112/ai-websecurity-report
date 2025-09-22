#!/bin/bash

V=""
OUTPUT_FILE="output.txt"
RESULT_FILE="result.txt"
WORDLIST_FILE="wordlist.txt"

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -V)
            if [[ -z "$2" ]]; then
                echo "Error: -V option requires an argument (target IP/hostname)."
                exit 1
            fi
            V="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option: $1"
            shift
            ;;
    esac
done

if [[ -z "$V" ]]; then
    echo "Usage: $0 -V <target_ip_or_hostname>"
    exit 1
fi

echo "Files cleared. Starting fresh!"
> "$OUTPUT_FILE"
> "$RESULT_FILE"

echo "--- Starting Scan for $V ---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Running Nmap scan..."
sudo nmap "$V" -oN "nmap_scan_$V.txt" >> "$OUTPUT_FILE" 2>&1

echo "Running Gobuster directory scan..."
sudo gobuster dir -u "http://$V/" -w "$WORDLIST_FILE" -o "gobuster_scan_$V.txt" >> "$OUTPUT_FILE" 2>&1

echo "Running Nping TCP scan..."
sudo nping --tcp -p 80 "$V" -o "nping_scan_$V.txt" >> "$OUTPUT_FILE" 2>&1

echo "Running Dirb scan..."
sudo dirb "http://$V/" "$WORDLIST_FILE" -o "dirb_scan_$V.txt" >> "$OUTPUT_FILE" 2>&1

echo "--- Scan complete for $V ---" >> "$OUTPUT_FILE"

echo ""
echo "Contents of $OUTPUT_FILE:"
cat "$OUTPUT_FILE"

echo ""
echo "Script finished."
