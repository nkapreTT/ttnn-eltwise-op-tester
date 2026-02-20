#!/bin/bash
# Complete workflow: Run accuracy test on Blackhole chip + generate plots + create PDF report
#
# Usage: ./run_accuracy_test_and_generate_pdf.sh <operation> <dtype>
# Example: ./run_accuracy_test_and_generate_pdf.sh gelu bfloat16

set -e

OPERATION=${1:-"gelu"}
DTYPE=${2:-"bfloat16"}

echo "=========================================="
echo "TTNN Accuracy Test & Report Generator"
echo "=========================================="
echo "Operation: ${OPERATION}"
echo "Data type: ${DTYPE}"
echo ""

# Check if PYTHONPATH is set to tt-metal
if [ -z "$PYTHONPATH" ] || [[ ! "$PYTHONPATH" =~ tt-metal ]]; then
    echo "Warning: PYTHONPATH may not include tt-metal"
    echo "Current PYTHONPATH: $PYTHONPATH"
    echo ""
    read -p "Do you want to set PYTHONPATH to /localdev/nkapre/tt-metal? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        export PYTHONPATH=/localdev/nkapre/tt-metal:$PYTHONPATH
        echo "✓ PYTHONPATH updated"
    fi
fi

# Step 1: Run accuracy measurement on Blackhole chip
echo "=========================================="
echo "Step 1/3: Running accuracy test on device"
echo "=========================================="
python3 measure_accuracy.py --operation "${OPERATION}" --type "${DTYPE}"

if [ $? -ne 0 ]; then
    echo "Error: Accuracy measurement failed"
    exit 1
fi

echo ""
echo "✓ Accuracy data collected"
echo ""

# Step 2: Generate plots from the data
echo "=========================================="
echo "Step 2/3: Generating plots"
echo "=========================================="

# Remove old plot to force regeneration
PLOT_PATH="accuracy_results/plots/unary/ulp/${OPERATION}/${OPERATION}-${DTYPE}.png"
if [ -f "$PLOT_PATH" ]; then
    echo "Removing old plot: $PLOT_PATH"
    rm -f "$PLOT_PATH"
fi

python3 plot.py -o "${OPERATION}"

if [ $? -ne 0 ]; then
    echo "Error: Plot generation failed"
    exit 1
fi

# Verify plot was created
if [ ! -f "$PLOT_PATH" ]; then
    echo "Warning: Plot not found at $PLOT_PATH"
    echo "Checking for alternative plots..."
    ls -la "accuracy_results/plots/unary/ulp/${OPERATION}/" || true
fi

echo ""
echo "✓ Plots generated"
echo ""

# Step 3: Generate PDF report using pandoc
echo "=========================================="
echo "Step 3/3: Generating PDF report"
echo "=========================================="

./generate_pdf.sh "${OPERATION}" "${DTYPE}"

echo ""
echo "=========================================="
echo "SUCCESS! Complete workflow finished"
echo "=========================================="
echo "Output files:"
echo "  - Accuracy data: accuracy_results/results/unary/${OPERATION}/${OPERATION}-${DTYPE}-[1].csv"
echo "  - Plot: ${PLOT_PATH}"
echo "  - PDF report: ${OPERATION}_report.pdf"
echo "=========================================="
