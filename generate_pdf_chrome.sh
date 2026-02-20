#!/bin/bash
# Generate accuracy PDF report using Chrome headless
# Supports multiple operations in a unified PDF
#
# Usage:
#   Single operation: ./generate_pdf_chrome.sh gelu bfloat16
#   Multiple operations: ./generate_pdf_chrome.sh "gelu,cos,sin" bfloat16
#   All operations: ./generate_pdf_chrome.sh all bfloat16

set -e

OPERATIONS_ARG=${1:-"gelu"}
DTYPE=${2:-"bfloat16"}

# Parse operations
if [ "$OPERATIONS_ARG" = "all" ]; then
    # All operations from report template
    OPERATIONS="gelu,cos,sin,cosh,sinh,tanh,exp,log,sigmoid"
elif [[ "$OPERATIONS_ARG" =~ "," ]]; then
    # Multiple operations (comma-separated)
    OPERATIONS="$OPERATIONS_ARG"
else
    # Single operation
    OPERATIONS="$OPERATIONS_ARG"
fi

# Convert to array
IFS=',' read -ra OPS_ARRAY <<< "$OPERATIONS"

echo "Generating PDF report for: ${OPS_ARRAY[@]} (${DTYPE})..."
echo ""

# Step 1: Generate markdown report using Jinja2 template
python3 << EOFPY
from jinja2 import Environment, FileSystemLoader
from datetime import datetime

env = Environment(loader=FileSystemLoader('templates'))
template = env.get_template('report.md.j2')

operations = '${OPERATIONS}'.split(',')
output_name = '_'.join(operations) if len(operations) <= 3 else f"{len(operations)}_operations"

with open(f'{output_name}_report.md', 'w') as f:
    f.write(template.render(
        unary_operations=operations,
        binary_operations=[],
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        dtypes=['${DTYPE}']
    ))

print(f'✓ Generated {output_name}_report.md')
print(f'Output filename base: {output_name}')
EOFPY

# Get output filename from python
OUTPUT_BASE=$(python3 -c "
operations = '${OPERATIONS}'.split(',')
output_name = '_'.join(operations) if len(operations) <= 3 else f\"{len(operations)}_operations\"
print(output_name)
")

# Step 2: Convert markdown to HTML with CSS styling
cat > /tmp/md2html_multi.py << 'EOFPY2'
import markdown
import sys

output_base = sys.argv[1]
dtype = sys.argv[2]

# Read markdown
with open(f'{output_base}_report.md', 'r') as f:
    md_content = f.read()

# Replace LaTeX \newpage with CSS page breaks
md_content = md_content.replace('\\newpage', '<div class="page-break"></div>')

# Convert to HTML
html_content = markdown.markdown(
    md_content,
    extensions=['extra', 'tables', 'fenced_code']
)

# Create full HTML with CSS page breaks and print styles
full_html = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>TTNN Accuracy Report - {output_base.replace('_', ', ').upper()}</title>
    <style>
        @media print {{
            @page {{ margin: 1in; }}
            body {{ font-size: 12pt; }}
            .page-break {{
                page-break-after: always;
                break-after: page;
            }}
        }}
        body {{
            font-family: 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            max-width: 900px;
            margin: 40px auto;
            padding: 20px;
            color: #333;
        }}
        .page-break {{
            page-break-after: always;
            break-after: page;
        }}
        h1 {{
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 15px;
            margin-top: 40px;
        }}
        h2 {{
            color: #34495e;
            border-bottom: 2px solid #95a5a6;
            padding-bottom: 10px;
            margin-top: 35px;
            page-break-after: avoid;
        }}
        h3 {{
            color: #7f8c8d;
            margin-top: 25px;
            page-break-after: avoid;
        }}
        table {{
            border-collapse: collapse;
            width: 100%;
            margin: 25px 0;
            box-shadow: 0 2px 3px rgba(0,0,0,0.1);
            page-break-inside: avoid;
        }}
        th, td {{
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }}
        th {{
            background-color: #3498db;
            color: white;
            font-weight: bold;
        }}
        tr:nth-child(even) {{ background-color: #f8f9fa; }}
        img {{
            max-width: 100%;
            height: auto;
            margin: 30px 0;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            page-break-inside: avoid;
        }}
        code {{
            background-color: #f4f4f4;
            padding: 3px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }}
        ul, ol {{ margin: 15px 0 15px 30px; }}
        li {{ margin: 8px 0; }}
    </style>
</head>
<body>
{html_content}
</body>
</html>
"""

with open(f'{output_base}_report.html', 'w') as f:
    f.write(full_html)

print(f'✓ Generated {output_base}_report.html')
EOFPY2

python3 /tmp/md2html_multi.py "${OUTPUT_BASE}" "${DTYPE}"

# Step 3: Convert HTML to PDF using Chrome headless
# This requires Chrome/Chromium to be installed
if command -v google-chrome &> /dev/null; then
    CHROME_BIN=google-chrome
elif command -v chromium &> /dev/null; then
    CHROME_BIN=chromium
elif command -v chromium-browser &> /dev/null; then
    CHROME_BIN=chromium-browser
elif [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
    echo "Error: Chrome/Chromium not found. Please install Chrome or use generate_report.py with pandoc+pdflatex"
    exit 1
fi

"$CHROME_BIN" --headless --disable-gpu --print-to-pdf="${OUTPUT_BASE}_report.pdf" "$(pwd)/${OUTPUT_BASE}_report.html" 2>&1 | grep -v "DevTools" || true

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
