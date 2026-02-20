#!/bin/bash
# Generate accuracy PDF report using pandoc + pdflatex
#
# Requirements:
#   - pandoc: apt-get install pandoc (Linux) or brew install pandoc (macOS)
#   - pdflatex: apt-get install texlive-latex-base texlive-fonts-recommended (Linux) 
#               or brew install basictex (macOS)
#
# Usage:
#   Single operation: ./generate_pdf.sh gelu bfloat16
#   Multiple operations: ./generate_pdf.sh "gelu,cos,sin" bfloat16

set -e

OPERATIONS_ARG=${1:-"gelu"}
DTYPE=${2:-"bfloat16"}

# Parse operations
if [ "$OPERATIONS_ARG" = "all" ]; then
    OPERATIONS="gelu,cos,sin,cosh,sinh,tanh,exp,log,sigmoid"
elif [[ "$OPERATIONS_ARG" =~ "," ]]; then
    OPERATIONS="$OPERATIONS_ARG"
else
    OPERATIONS="$OPERATIONS_ARG"
fi

# Convert to array
IFS=',' read -ra OPS_ARRAY <<< "$OPERATIONS"

echo "Generating PDF report for: ${OPS_ARRAY[@]} (${DTYPE})..."
echo ""

# Determine output filename
if [ ${#OPS_ARRAY[@]} -le 3 ]; then
    OUTPUT_BASE="${OPERATIONS//,/_}"
else
    OUTPUT_BASE="${#OPS_ARRAY[@]}_operations"
fi

# Step 1: Generate markdown report using Jinja2 template
python3 << EOFPY
from jinja2 import Environment, FileSystemLoader
from datetime import datetime

env = Environment(loader=FileSystemLoader('templates'))
template = env.get_template('report.md.j2')

operations = '${OPERATIONS}'.split(',')

with open('${OUTPUT_BASE}_report.md', 'w') as f:
    f.write(template.render(
        unary_operations=operations,
        binary_operations=[],
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        dtypes=['${DTYPE}']
    ))

print('✓ Generated ${OUTPUT_BASE}_report.md')
EOFPY

# Step 2: Convert markdown to PDF using pandoc + pdflatex
echo "Converting to PDF with pandoc..."

if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc not found"
    echo "Install: apt-get install pandoc (Linux) or brew install pandoc (macOS)"
    exit 1
fi

if ! command -v pdflatex &> /dev/null; then
    echo "Error: pdflatex not found"
    echo "Install: apt-get install texlive-latex-base texlive-fonts-recommended (Linux)"
    echo "         brew install --cask basictex (macOS)"
    exit 1
fi

pandoc "${OUTPUT_BASE}_report.md" \
    -f markdown \
    -o "${OUTPUT_BASE}_report.pdf" \
    --pdf-engine=pdflatex \
    -V geometry:margin=1in \
    -V fontsize=11pt \
    -V colorlinks=true \
    -V linkcolor=blue \
    --highlight-style=tango \
    2>&1 | grep -v "LaTeX Warning" || true

if [ -f "${OUTPUT_BASE}_report.pdf" ]; then
    echo "✓ PDF generated: ${OUTPUT_BASE}_report.pdf"
    ls -lh "${OUTPUT_BASE}_report.pdf"
else
    echo "Error: PDF generation failed"
    exit 1
fi

echo ""
echo "==================================================="
echo "SUCCESS: Report generated successfully!"
echo "PDF: ${OUTPUT_BASE}_report.pdf"
echo "Operations: ${OPS_ARRAY[@]}"
echo "==================================================="
