#!/usr/bin/env bash
set -euo pipefail

V=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --V) V="$2"; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

if [[ -z "$V" ]]; then
  echo "❌ No target provided. Use: ./scan_and_scrape.sh --V <target>"
  exit 2
fi

TS=$(date +%Y%m%d_%H%M%S)
OUTDIR="scan_outputs_${TS}"
mkdir -p "$OUTDIR"

COMBINED="${OUTDIR}/combined.txt"
RESULTS_TXT="${OUTDIR}/results.txt"
DATASCRAPER="${OUTDIR}/datascraper.txt"

: > "$COMBINED"
: > "$DATASCRUTAPER" 2>/dev/null || : > "$DATASCRAPER"
: > "$RESULTS_TXT"

echo "[*] Outputs will be in: $OUTDIR"
echo "[*] Combined log: $COMBINED"

run_and_log() {
  local label="$1"; shift
  local outfile="$1"; shift
  echo "----- [$label] $(date --iso-8601=seconds) -----" | tee -a "$COMBINED" >> "$outfile"
  if "$@" >> "$outfile" 2>&1; then
    echo "[OK] $label finished." | tee -a "$COMBINED"
  else
    echo "[ERR] $label returned non-zero exit status." | tee -a "$COMBINED"
  fi
  echo -e "\n\n" >> "$COMBINED"
}

NMAP_OUT="${OUTDIR}/nmap.txt"
echo "[*] Running nmap (this may take a while)..."
run_and_log "nmap" "$NMAP_OUT" sudo nmap -sV -p- --open "$V"

GOB_OUT="${OUTDIR}/gobuster.txt"
echo "[*] Running gobuster (dir bust)..."
if [[ ! -f wordlist.txt ]]; then
  echo "⚠️ wordlist.txt not found in current directory. Create or provide one." | tee -a "$COMBINED"
else
  run_and_log "gobuster" "$GOB_OUT" sudo gobuster dir -u "https://${V}/" -w wordlist.txt -o "$GOB_OUT"
fi

NPING_OUT="${OUTDIR}/nping.txt"
echo "[*] Running nping (TCP ping to port 80)..."
run_and_log "nping" "$NPING_OUT" sudo nping --tcp -p 80 -c 5 "$V"

DIRB_OUT="${OUTDIR}/dirb.txt"
echo "[*] Running dirb..."
if [[ ! -f wordlist.txt ]]; then
  echo "⚠️ wordlist.txt not found; skipping dirb." | tee -a "$COMBINED"
else
  run_and_log "dirb" "$DIRB_OUT" sudo dirb "http://${V}/" wordlist.txt -o "$DIRB_OUT"
fi

if [[ -x "endresult1.py" || -f "endresult1.py" ]]; then
  echo "[*] Running python endresult1.py (if required)..."
  run_and_log "python endresult1.py" "${OUTDIR}/endresult1.txt" python3 endresult1.py
fi

if [[ -x "endresult2.py" || -f "endresult2.py" ]]; then
  echo "[*] Running python endresult2.py (if required)..."
  run_and_log "python endresult2.py" "${OUTDIR}/endresult2.txt" python3 endresult2.py
fi

if [[ -f "./results.txt" ]]; then
  SRC_RESULTS="./results.txt"
  echo "[*] Found local ./results.txt — using that as list of paths."
elif [[ -s "$RESULTS_TXT" ]]; then
  SRC_RESULTS="$RESULTS_TXT"
  echo "[*] Using generated results file: $RESULTS_TXT"
else
  echo "[*] No results.txt found. Attempting to extract paths from gobuster/dirb outputs..."
  grep -h -Eo '/[A-Za-z0-9/_\.\-]+' "$GOB_OUT" "$DIRB_OUT" 2>/dev/null | sort -u > "$RESULTS_TXT" || true
  if [[ -s "$RESULTS_TXT" ]]; then
    SRC_RESULTS="$RESULTS_TXT"
    echo "[*] Extracted paths saved to $RESULTS_TXT"
  else
    echo "⚠️ No paths to curl were found. Skipping curl loop." | tee -a "$COMBINED"
    SRC_RESULTS=""
  fi
fi

if [[ -n "${SRC_RESULTS:-}" && -f "$SRC_RESULTS" ]]; then
  echo "[*] Curling each path from $SRC_RESULTS into $DATASCRAPER (slow; be polite)"
  : > "$DATASCRAPER"
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    [[ "$path" =~ ^# ]] && continue
    if [[ "$path" =~ ^https?:// ]]; then
      url="$path"
    else
      [[ "$path" != /* ]] && path="/$path"
      url="http://${V}${path}"
    fi
    echo "----- [$url] -----" >> "$DATASCRAPER"
    curl -sS --fail --location "$url" >> "$DATASCRAPER" 2>&1 || echo "[ERR] curl failed for $url" >> "$DATASCRAPER"
    echo -e "\n\n" >> "$DATASCRAPER"
  done < "$SRC_RESULTS"
  echo "✅ All curl responses appended to: $DATASCRAPER"
fi

if [[ -f "summary.txt" ]]; then
  echo "----- summary.txt -----"
  cat summary.txt
fi

echo "[*] Done. Collected outputs: "
ls -lh "$OUTDIR" || true
