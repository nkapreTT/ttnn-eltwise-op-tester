#!/bin/bash
# Generate accuracy PDF report using Chrome headless
# Alternative to pandoc+pdflatex for systems without LaTeX installed

set -e

OPERATION=${1:-"gelu"}
DTYPE=${2:-"bfloat16"}

echo "Generating PDF report for ${OPERATION} (${DTYPE})..."

# Step 1: Generate markdown report using Jinja2 template
python3 << EOFPY
from jinja2 import Environment, FileSystemLoader
from datetime import datetime

env = Environment(loader=FileSystemLoader('templates'))
template = env.get_template('report.md.j2')

with open('${OPERATION}_report.md', 'w') as f:
    f.write(template.render(
        unary_operations=['${OPERATION}'],
        binary_operations=[],
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        dtypes=['${DTYPE}']
    ))

print('✓ Generated ${OPERATION}_report.md')
EOFPY

# Step 2: Convert markdown to HTML with CSS styling
cat > /tmp/md2html_${OPERATION}.py << 'EOFPY2'
import markdown
import sys

operation = sys.argv[1]
dtype = sys.argv[2]

# Read markdown
with open(f'{operation}_report.md', 'r') as f:
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
    <title>{operation.upper()} Accuracy Report</title>
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

with open(f'{operation}_report.html', 'w') as f:
    f.write(full_html)

print(f'✓ Generated {operation}_report.html')
EOFPY2

python3 /tmp/md2html_${OPERATION}.py "${OPERATION}" "${DTYPE}"

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

"$CHROME_BIN" --headless --disable-gpu --print-to-pdf="${OPERATION}_report.pdf" "$(pwd)/${OPERATION}_report.html" 2>&1 | grep -v "DevTools" || true

if [ -f "${OPERATION}_report.pdf" ]; then
    echo "✓ PDF generated: ${OPERATION}_report.pdf"
    ls -lh "${OPERATION}_report.pdf"
else
    echo "Error: PDF generation failed"
    exit 1
fi

echo ""
echo "==================================================="
echo "SUCCESS: Report generated successfully!"
echo "PDF: ${OPERATION}_report.pdf"
echo "==================================================="
