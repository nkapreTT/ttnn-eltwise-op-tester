# TTNN Eltwise Operation Tester

Test and plot accuracy of TTNN's element-wise operations.

## Quick Start

```bash
# Run all 36 unary operation tests and generate comprehensive PDF report
./run_all_unary_tests.sh bfloat16

# Generate PDF from existing data only (no testing)
./generate_all_unary_pdf.sh bfloat16

# Single operation workflow: test + plot + PDF
./run_accuracy_test_and_generate_pdf.sh gelu bfloat16
```

## Setup

This repository relies on tt-metal configuration.

```bash
PYTHONPATH=<path/to/tt-metal>
TT_METAL_HOME=<path/to/tt-metal>
source <path/to/tt-metal>/python_env/bin/activate
```

### Dependencies

**Python packages:**
```bash
pip install -r requirements.txt
# Or manually:
pip install matplotlib seaborn pandas numpy scipy loguru jinja2 markdown
```

**System packages for PDF generation:**
```bash
# Linux (Ubuntu/Debian)
sudo apt-get install pandoc texlive-full

# macOS
brew install pandoc basictex
```

## Directory Structure

```
├── configs/
│   ├── unary-plots.json                    # Plot configuration for unary operations
│   └── binary-plots.json                   # Plot configuration for binary operations
├── accuracy_results/
│   ├── results/
│   │   ├── unary/                          # Raw accuracy measurement results (CSV)
│   │   └── binary/                         # Raw accuracy measurement results (CSV)
│   └── plots/
│       ├── unary/                          # Generated plots for unary operations
│       └── binary/                         # Generated plots for binary operations
├── templates/
│   └── report.md.j2                        # Jinja2 template for PDF report
├── measure_accuracy.py                     # Main script for accuracy measurements
├── plot.py                                 # Plot generation for unary operations
├── plot_binary.py                          # Plot generation for binary operations
├── generate_report.py                      # PDF report generation (Python)
├── generate_pdf.sh                         # PDF generation (pandoc + pdflatex)
├── run_all_unary_tests.sh                  # Run all 36 unary ops + generate PDF
├── generate_all_unary_pdf.sh               # Generate PDF from existing data
├── run_accuracy_test_and_generate_pdf.sh   # Single operation: test + plot + PDF
└── requirements.txt                        # Python dependencies
```

## Workflow Scripts

Automated scripts for running tests and generating PDF reports.

### Run All Unary Operations

Test all 36 unary operations and generate comprehensive PDF report:

```bash
./run_all_unary_tests.sh [dtype]
# Example: ./run_all_unary_tests.sh bfloat16
```

**What it does:**
1. Runs accuracy tests for operations that don't have data yet
2. Regenerates all plots
3. Generates comprehensive PDF with all successful operations

**Output:** `{N}_operations_report.pdf` (e.g., `36_operations_report.pdf`)

### Generate PDF from Existing Data

Create PDF report without running new tests:

```bash
./generate_all_unary_pdf.sh [dtype]
# Example: ./generate_all_unary_pdf.sh bfloat16
```

**What it does:**
1. Scans for existing accuracy data
2. Regenerates plots
3. Generates PDF with all operations that have data

**Use case:** When you've already run tests and just want to regenerate the PDF.

### Single Operation Workflow

Complete workflow for a single operation (test → plot → PDF):

```bash
./run_accuracy_test_and_generate_pdf.sh <operation> <dtype>
# Example: ./run_accuracy_test_and_generate_pdf.sh gelu bfloat16
```

**What it does:**
1. Runs accuracy measurement on device
2. Generates plots for the operation
3. Creates PDF report

**Output:** `{operation}_report.pdf` (e.g., `gelu_report.pdf`)

### Custom PDF Generation

Generate PDF for specific operations:

```bash
./generate_pdf.sh "op1,op2,op3" dtype
# Example: ./generate_pdf.sh "gelu,cos,sin" bfloat16
```

**Output:** Depends on number of operations:
- ≤3 ops: `op1_op2_op3_report.pdf`
- \>3 ops: `{N}_operations_report.pdf`

### Supported Unary Operations (36 total)

**Basic:** abs, identity, exp, exp2, expm1, log, log10, log2, log1p
**Trigonometric:** sin, cos, tan, atan, sinh, cosh, tanh
**Activation:** relu, gelu, selu, elu, celu, silu, swish, mish, sigmoid, log_sigmoid, logit, softplus, softsign, tanhshrink
**Root/Reciprocal:** sqrt, cbrt, rsqrt, reciprocal
**Special:** digamma, lgamma, erfinv

## Accuracy Benchmark

The `measure_accuracy.py` script measures accuracy for both unary and binary operations. The operation type is automatically detected.

### Unary Operations

#### bfloat16
```bash
python measure_accuracy.py -t "bfloat16"
```

Test a specific operation:
```bash
python measure_accuracy.py -t "bfloat16" -o "exp"
```

#### float32
> Note: Not optimized, takes ~2 minutes per operation

```bash
python measure_accuracy.py -t "float32"
```

### Binary Operations

```bash
python measure_accuracy.py -t "bfloat16" -o "atan2"
```

### Command Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--type` | `-t` | Data type (`bfloat16` or `float32`) | `bfloat16` |
| `--operation` | `-o` | Specific operation to test | All operations |
| `--output-dir` | `-O` | Output directory for results | `accuracy_results/results/` |
| `--group-size` | `-g` | Measurement batch size (unary only) | 1 (bf16) / 65536 (f32) |

## Plot Generation

### Unary Operations

```bash
python plot.py
```

Reads configuration from `configs/unary-plots.json` and outputs plots to `accuracy_results/plots/unary/`.

**Plot types:**
- **ULP error plots:** Scatter plots showing all sampled points with log scale
- **Zoom plots:** Relative error plots focused on low-error regions
- **Value plots:** Comparison of TTNN output vs reference values

**Features:**
- ULP statistics inset (max ULP per operation)
- Automatic legend hiding for single implementations
- Clean x-axis labels showing operation domains
- Configurable via `configs/unary-plots.json`

### Binary Operations

```bash
python plot_binary.py
```

Reads configuration from `configs/binary-plots.json` and outputs plots to `accuracy_results/plots/binary/`.

## PDF Report Generation

Generate comprehensive PDF reports with accuracy plots and statistics.

### Using Shell Scripts (Recommended)

**All operations:**
```bash
./run_all_unary_tests.sh bfloat16        # Run tests + generate PDF
./generate_all_unary_pdf.sh bfloat16     # Generate PDF from existing data
```

**Specific operations:**
```bash
./generate_pdf.sh "gelu,cos,sin" bfloat16
```

**Single operation:**
```bash
./run_accuracy_test_and_generate_pdf.sh gelu bfloat16
```

### Using Python (Legacy)

```bash
python generate_report.py
```

**Output files:**
- `accuracy_report.md` - Markdown report with all plots
- `accuracy_report.pdf` - PDF report

### PDF Features

Generated PDFs include:
- **ULP error plots** with log scale for full range visibility
- **ULP statistics inset** showing max ULP for each operation
- **Zoom plots** highlighting low-error regions
- **Value plots** comparing TTNN output vs reference
- Clean x-axis labels showing operation domains (e.g., [-π, π] for trig functions)
- Automatic legend hiding for single-implementation operations

## Troubleshooting

### No plots found
Ensure:
1. Accuracy data exists in `accuracy_results/results/`
2. Plot configuration files are present in `configs/`
3. Run the plot generation scripts first (`plot.py`, `plot_binary.py`)

### PDF conversion fails
1. Verify pandoc and LaTeX (pdflatex) are installed
2. Check that the markdown file was created
3. Manual conversion: `pandoc accuracy_report.md -o accuracy_report.pdf --pdf-engine=pdflatex`

### Plot generation fails
1. Check that all required Python packages are installed
2. Verify that accuracy data files exist in `accuracy_results/results/`
3. Check plot configuration files in `configs/` for syntax errors

## Example Workflows

### Complete Workflow: All Operations

```bash
# 1. Set up environment
cd /path/to/ttnn-eltwise-op-tester
source <path/to/tt-metal>/python_env/bin/activate
export PYTHONPATH=<path/to/tt-metal>
export TT_METAL_HOME=<path/to/tt-metal>

# 2. Install dependencies (first time only)
pip install -r requirements.txt
sudo apt-get install pandoc texlive-full  # Linux

# 3. Run all tests and generate PDF (one command!)
./run_all_unary_tests.sh bfloat16

# 4. View the PDF
ls -lh *_operations_report.pdf
```

### Quick Workflow: Single Operation

```bash
# Set up environment (if needed)
export PYTHONPATH=<path/to/tt-metal>

# Test, plot, and generate PDF for one operation
./run_accuracy_test_and_generate_pdf.sh gelu bfloat16

# View the result
ls -lh gelu_report.pdf
```

### Manual Workflow (Step-by-Step)

```bash
# 1. Run accuracy measurements
python measure_accuracy.py -t "bfloat16" -o "gelu"

# 2. Generate plots
python plot.py

# 3. Generate PDF
./generate_pdf.sh "gelu" bfloat16
```

### Regenerate PDF Only

If you've already run tests and just want to update the PDF:

```bash
# Regenerate plots and PDF from existing data
./generate_all_unary_pdf.sh bfloat16
```

## Notes

### Testing & Accuracy
- **BF16 exhaustive testing:** Tests all ~65,536 representable BF16 values within operation domain
- **Float32 testing:** Samples 65,536 uniformly distributed points (slower)
- **ULP errors:** Measured against reference implementations (NumPy/SciPy)
- **Operation domains:** Configured in `configs/unary-plots.json` (e.g., [-π, π] for trig functions)

### Plots & Reports
- Plots organized by error type (ULP, relative, value)
- ULP plots use log scale to show full error range (e.g., 0.1 to 1e36)
- Scatter plots show all sampled points (no aggregation)
- PDF reports include table of contents for easy navigation
- Plot generation uses multiprocessing for speed

### Performance
- Single operation test: ~1-5 seconds (BF16), ~2 minutes (Float32)
- All 36 operations: ~3-5 minutes (BF16)
- Plot generation: ~10-30 seconds for all operations
- PDF generation: ~5-10 seconds with pandoc

### Caching
- Plot hashes cached in `accuracy_results/plot-hashes.csv`
- Plots regenerated only when data changes
- Delete cache to force regeneration: `rm accuracy_results/plot-hashes.csv`
