#!/bin/bash
# Generate PDF report from all existing unary operation data
# Does NOT run tests - only creates PDF from existing results
#
# Requirements: pandoc, pdflatex (see generate_pdf.sh for install instructions)
#
# Usage: ./generate_all_unary_pdf.sh [dtype]
# Example: ./generate_all_unary_pdf.sh bfloat16

set -e

DTYPE=${1:-"bfloat16"}

echo "=========================================="
echo "Generating PDF from existing unary data"
echo "=========================================="
echo "Data type: ${DTYPE}"
echo ""

# List of all unary operations
ALL_UNARY_OPS=(
    "abs" "identity" "exp" "exp2" "expm1" "log" "log10" "log2" "log1p"
    "tanh" "cosh" "sinh" "tan" "atan" "cos" "sin"
    "silu" "gelu" "logit" "swish" "mish" "elu" "celu"
    "sigmoid" "log_sigmoid" "selu" "softplus" "softsign"
    "sqrt" "relu" "cbrt" "rsqrt" "reciprocal"
    "digamma" "lgamma" "tanhshrink" "erfinv"
)

# Find operations that have data
OPS_WITH_DATA=()
OPS_WITHOUT_DATA=()

for op in "${ALL_UNARY_OPS[@]}"; do
    DATA_FILE="accuracy_results/results/unary/${op}/${op}-${DTYPE}-[1].csv"
    if [ -f "$DATA_FILE" ]; then
        OPS_WITH_DATA+=("$op")
        echo "✓ Found data: $op"
    else
        OPS_WITHOUT_DATA+=("$op")
    fi
done

echo ""
echo "=========================================="
echo "Data Summary"
echo "=========================================="
echo "Operations with data: ${#OPS_WITH_DATA[@]}"
echo "Operations without data: ${#OPS_WITHOUT_DATA[@]}"

if [ ${#OPS_WITHOUT_DATA[@]} -gt 0 ]; then
    echo ""
    echo "Operations without data (run tests first):"
    printf '  - %s\n' "${OPS_WITHOUT_DATA[@]}"
fi

if [ ${#OPS_WITH_DATA[@]} -eq 0 ]; then
    echo ""
    echo "Error: No operations have data. Run tests first with:"
    echo "  ./run_all_unary_tests.sh $DTYPE"
    exit 1
fi

echo ""
echo "=========================================="
echo "Generating plots"
echo "=========================================="

# Check PYTHONPATH
if [ -z "$PYTHONPATH" ] || [[ ! "$PYTHONPATH" =~ tt-metal ]]; then
    echo "Setting PYTHONPATH to /localdev/nkapre/tt-metal"
    export PYTHONPATH=/localdev/nkapre/tt-metal:$PYTHONPATH
fi

# Regenerate plots
python3 plot.py 2>&1 | tail -20

echo ""
echo "✓ Plots updated"

echo ""
echo "=========================================="
echo "Generating PDF"
echo "=========================================="

# Join array with commas
OPS_LIST=$(IFS=, ; echo "${OPS_WITH_DATA[*]}")

echo "Including ${#OPS_WITH_DATA[@]} operations in PDF"

./generate_pdf.sh "$OPS_LIST" "$DTYPE"

echo ""
echo "=========================================="
echo "SUCCESS!"
echo "=========================================="
echo "PDF generated with ${#OPS_WITH_DATA[@]} operations"

# Determine output filename
if [ ${#OPS_WITH_DATA[@]} -le 5 ]; then
    OUTPUT_PDF="${OPS_LIST/,/_}_report.pdf"
else
    OUTPUT_PDF="${#OPS_WITH_DATA[@]}_operations_report.pdf"
fi

if [ -f "$OUTPUT_PDF" ]; then
    ls -lh "$OUTPUT_PDF"
else
    echo "PDF file: (check current directory)"
    ls -lh *_report.pdf 2>/dev/null || echo "No PDF found"
fi

echo "=========================================="
