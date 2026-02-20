#!/bin/bash
# Run accuracy tests for all unary operations and generate comprehensive PDF report
#
# Requirements: pandoc, pdflatex (see generate_pdf.sh for install instructions)
#
# Usage: ./run_all_unary_tests.sh [dtype]
# Example: ./run_all_unary_tests.sh bfloat16

set -e

DTYPE=${1:-"bfloat16"}

# List of all unary operations from generate_report.py
ALL_UNARY_OPS=(
    "abs" "identity" "exp" "exp2" "expm1" "log" "log10" "log2" "log1p"
    "tanh" "cosh" "sinh" "tan" "atan" "cos" "sin"
    "silu" "gelu" "logit" "swish" "mish" "elu" "celu"
    "sigmoid" "log_sigmoid" "selu" "softplus" "softsign"
    "sqrt" "relu" "cbrt" "rsqrt" "reciprocal"
    "digamma" "lgamma" "tanhshrink" "erfinv"
)

echo "=========================================="
echo "Running All Unary Operations Tests"
echo "=========================================="
echo "Data type: ${DTYPE}"
echo "Total operations: ${#ALL_UNARY_OPS[@]}"
echo ""

# Check PYTHONPATH
if [ -z "$PYTHONPATH" ] || [[ ! "$PYTHONPATH" =~ tt-metal ]]; then
    echo "Setting PYTHONPATH to /localdev/nkapre/tt-metal"
    export PYTHONPATH=/localdev/nkapre/tt-metal:$PYTHONPATH
fi

FAILED_OPS=()
SUCCEEDED_OPS=()
SKIPPED_OPS=()

# Step 1: Run accuracy tests for operations that don't have data yet
echo "=========================================="
echo "Step 1: Running accuracy tests"
echo "=========================================="

for op in "${ALL_UNARY_OPS[@]}"; do
    DATA_FILE="accuracy_results/results/unary/${op}/${op}-${DTYPE}-[1].csv"

    if [ -f "$DATA_FILE" ]; then
        echo "✓ Skipping $op (data already exists)"
        SKIPPED_OPS+=("$op")
    else
        echo ""
        echo ">>> Running test: $op"
        if timeout 300 python3 measure_accuracy.py --operation "$op" --type "$DTYPE" 2>&1 | tee "/tmp/${op}_test.log"; then
            SUCCEEDED_OPS+=("$op")
            echo "✓ Success: $op"
        else
            FAILED_OPS+=("$op")
            echo "✗ Failed: $op"
        fi
    fi
done

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Skipped (already tested): ${#SKIPPED_OPS[@]}"
echo "Newly tested: ${#SUCCEEDED_OPS[@]}"
echo "Failed: ${#FAILED_OPS[@]}"

if [ ${#FAILED_OPS[@]} -gt 0 ]; then
    echo ""
    echo "Failed operations:"
    printf '%s\n' "${FAILED_OPS[@]}"
fi

# Step 2: Generate plots for all operations
echo ""
echo "=========================================="
echo "Step 2: Generating plots for all operations"
echo "=========================================="

# Force regenerate all plots
rm -f accuracy_results/plot-hashes.csv

python3 plot.py 2>&1 | tail -50

echo ""
echo "✓ Plots generated"

# Step 3: Generate unified PDF with all operations that have data
echo ""
echo "=========================================="
echo "Step 3: Generating comprehensive PDF report"
echo "=========================================="

# Build list of operations that have data
OPS_WITH_DATA=()
for op in "${ALL_UNARY_OPS[@]}"; do
    DATA_FILE="accuracy_results/results/unary/${op}/${op}-${DTYPE}-[1].csv"
    if [ -f "$DATA_FILE" ]; then
        OPS_WITH_DATA+=("$op")
    fi
done

echo "Operations with data: ${#OPS_WITH_DATA[@]}"

# Join array with commas
OPS_LIST=$(IFS=, ; echo "${OPS_WITH_DATA[*]}")

echo "Generating PDF for: $OPS_LIST"
./generate_pdf.sh "$OPS_LIST" "$DTYPE"

echo ""
echo "=========================================="
echo "COMPLETE!"
echo "=========================================="
echo "Total operations tested: ${#OPS_WITH_DATA[@]}"
echo "PDF report: ${#OPS_WITH_DATA[@]}_operations_report.pdf"
echo ""
echo "Summary:"
echo "  - Already had data: ${#SKIPPED_OPS[@]} operations"
echo "  - Newly tested: ${#SUCCEEDED_OPS[@]} operations"
echo "  - Failed: ${#FAILED_OPS[@]} operations"
echo "  - In PDF: ${#OPS_WITH_DATA[@]} operations"
echo "=========================================="

# Show failed operations again at the end
if [ ${#FAILED_OPS[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Failed operations (not in PDF):"
    printf '  - %s\n' "${FAILED_OPS[@]}"
fi
