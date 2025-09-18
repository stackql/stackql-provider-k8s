#!/usr/bin/env bash

# Exit on error
set -e

# Get the script directory for relative paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default values
PROVIDER_NAME=""
INPUT_DIR=""
OUTPUT_DIR=""
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --provider-name)
      PROVIDER_NAME="$2"
      shift 2
      ;;
    --input-dir)
      INPUT_DIR="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "Usage: generate-mappings.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --provider-name NAME        Provider name (required)"
      echo "  --input-dir DIR             Input directory containing split OpenAPI files (required)"
      echo "  --output-dir DIR            Output directory for mapping file (required)"
      echo "  --verbose                   Enable verbose output"
      echo "  --help                      Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check required arguments
if [ -z "$PROVIDER_NAME" ] || [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Error: Missing required arguments"
  echo "Use --help for usage information"
  exit 1
fi

echo "🔍 Analyzing OpenAPI specs to generate mappings..."
echo "Provider: $PROVIDER_NAME"
echo "Input Directory: $INPUT_DIR"
echo "Output Directory: $OUTPUT_DIR"

# Build command arguments
ARGS=("--provider-name" "$PROVIDER_NAME" "--input-dir" "$INPUT_DIR" "--output-dir" "$OUTPUT_DIR")

if [ "$VERBOSE" = true ]; then
  ARGS+=("--verbose")
  echo "Verbose: Yes"
fi

# Run the Node.js script with arguments
node --experimental-modules "$SCRIPT_DIR/generate-mappings.mjs" "${ARGS[@]}"

# Check if command succeeded
if [ $? -ne 0 ]; then
    echo "❌ Mapping generation failed"
    exit 1
fi

echo "✅ Mapping file generated successfully at: $OUTPUT_DIR/all_services.csv"