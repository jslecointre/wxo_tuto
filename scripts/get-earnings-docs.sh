#!/usr/bin/env bash
# Download the earnings documents used in part 3 (Develop agents with no code) into data/earnings/.
# PDFs are downloaded as is; the Coca-Cola HTML earnings releases are printed to PDF with headless Chrome
# so they can be uploaded as knowledge in watsonx Orchestrate.
set -euo pipefail

OUT="${1:-data/earnings}"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

mkdir -p "$OUT/pepsico" "$OUT/coca-cola"

FAILED=()

is_pdf() { [ -s "$1" ] && [ "$(head -c 4 "$1")" = "%PDF" ]; }

pdf() { # <dest> <url>
  echo "  $1"
  # A moved document redirects to an HTML page: keep only real PDFs.
  curl -fsSL -A "$UA" -o "$1" "$2" || true
  if ! is_pdf "$1"; then
    rm -f "$1"
    FAILED+=("$1  <-  $2")
  fi
}

html_to_pdf() { # <dest> <url>
  echo "  $1 (HTML page printed to PDF)"
  if [ ! -x "$CHROME" ]; then
    echo "warning: Chrome not found at $CHROME — saving the HTML page instead (set CHROME=... to fix)" >&2
    curl -fsSL -A "$UA" -o "${1%.pdf}.html" "$2"
    return
  fi
  "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf="$1" "$2" 2>/dev/null
}

echo "PepsiCo -> $OUT/pepsico"
pdf "$OUT/pepsico/pepsico-q2-2025-press-release.pdf" \
  "https://investors.pepsico.com/docs/pepsico-5v9wci20/media/Files/investors/q2-2025-earnings-release.pdf"
pdf "$OUT/pepsico/pepsico-q2-2025-remarks.pdf" \
  "https://investors.pepsico.com/docs/pepsico-5v9wci20/media/Files/investors/q2-2025-prepared-management-remarks.pdf"
pdf "$OUT/pepsico/pepsico-q2-2020-press-release.pdf" \
  "https://investors.pepsico.com/docs/pepsico-5v9wci20/media/Files/investors/q2-2020-earnings-release.pdf"
pdf "$OUT/pepsico/pepsico-q2-2020-remarks.pdf" \
  "https://investors.pepsico.com/docs/pepsico-5v9wci20/media/Files/investors/q2-2020-transcript-pre-recorded-management-discussion.pdf"

echo "Coca-Cola -> $OUT/coca-cola"
html_to_pdf "$OUT/coca-cola/coca-cola-q2-2025-earnings-release.pdf" \
  "https://investors.coca-colacompany.com/news-events/press-releases/detail/1138/coca-cola-reports-second-quarter-2025-results-and-updates-full-year-guidance"
pdf "$OUT/coca-cola/coca-cola-q2-2025-transcript.pdf" \
  "https://investors.coca-colacompany.com/_assets/_e651d8ca9b7c4138098b4871af1d3bad/cocacolacompany/db/880/11064/webcast_transcript/CORRECTED+TRANSCRIPT_+The+Coca-Cola+Co.%28KO-US%29%2C+Q2+2025+Earnings+Call%2C+22-July-2025+8_30+AM+ET.pdf"
html_to_pdf "$OUT/coca-cola/coca-cola-q2-2020-earnings-release.pdf" \
  "https://investors.coca-colacompany.com/news-events/press-releases/detail/994/coca-cola-reports-second-quarter-2020-results-provides-update-on-strategic-actions-in-rapidly-evolving-business-climate"
pdf "$OUT/coca-cola/coca-cola-q2-2020-transcript.pdf" \
  "https://investors.coca-colacompany.com/_assets/_e651d8ca9b7c4138098b4871af1d3bad/cocacolacompany/db/880/10224/webcast_transcript/CORRECTED%2BTRANSCRIPT_%2BThe%2BCoca-Cola%2BCo.%2528KO-US%2529%252C%2BQ2%2B2020%2BEarnings%2BCall%252C%2B21-July-2020%2B8_30%2BAM%2BET.pdf"

ls -lh "$OUT"/pepsico "$OUT"/coca-cola
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "" >&2
  echo "error: these files are not valid PDFs (moved or blocked document)." >&2
  echo "Open each URL in your browser and save the PDF to the path shown:" >&2
  printf '  %s\n' "${FAILED[@]}" >&2
  exit 1
fi
echo "✔ all documents downloaded"
