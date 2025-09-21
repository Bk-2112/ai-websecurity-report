while [[ "$#" -gt 0 ]]; do
    case $1 in
        --V) V="$2"; shift ;;   # capture value of --V
    esac
    shift
done

> output.txt
> result.txt

# OR equivalently:
# : > file1.txt
# : > file2.txt

echo "Files cleared. Starting fresh!"

# Example: write something new
echo " " >> output.txt
echo " " >> output.txt

sudo nmap $V -o output.txt
sudo gobuster dir -u "https://"$V"/" -w wordlist.txt -o output.txt

sudo nping --tcp -p 80 $V -o output.txt
sudo dirb http://$V/ wordlist.txt -o output.txt

python endresult1.py

#!/bin/bash

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --V) V="$2"; shift ;;   # Capture IP
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if IP was provided
if [ -z "$V" ]; then
    echo "❌ No IP address provided. Use: ./script.bash --V <ip>"
    exit 1
fi

# Clear old result file
> result.txt

# Loop through each line in results.txt and curl
while IFS= read -r path; do
    echo "----- [$path] -----" >> result.txt
    curl -s "http://$V$path" >> result.txt
    echo -e "\n\n" >> result.txt
done < results.txt

echo "✅ All responses saved to result.txt"

python endresult2.py

cat summary.txt
