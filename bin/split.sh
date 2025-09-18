#!/usr/bin/env bash

# Exit on error
set -e

# Get the script directory for relative paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default values
PROVIDER_NAME=""
API_DOC=""
OUTPUT_DIR=""
SVC_DISCRIMINATOR="tag"
EXCLUDE=""
OVERWRITE=false
VERBOSE=false
SVC_NAME_OVERRIDES="{}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --provider-name)
      PROVIDER_NAME="$2"
      shift 2
      ;;
    --api-doc)
      API_DOC="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --svc-discriminator)
      SVC_DISCRIMINATOR="$2"
      shift 2
      ;;
    --exclude)
      EXCLUDE="$2"
      shift 2
      ;;
    --svc-name-overrides)
      SVC_NAME_OVERRIDES="$2"
      shift 2
      ;;
    --overwrite)
      OVERWRITE=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "Usage: split.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --provider-name NAME        Provider name (required)"
      echo "  --api-doc PATH              Path to OpenAPI document (required)"
      echo "  --output-dir DIR            Output directory for split files (required)"
      echo "  --svc-discriminator TYPE    Service discriminator type: 'tag' or 'path' (default: tag)"
      echo "  --exclude LIST              Comma-separated list of tags or paths to exclude"
      echo "  --svc-name-overrides JSON   JSON object mapping original service names to new names"
      echo "  --overwrite                 Overwrite existing files"
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
if [ -z "$PROVIDER_NAME" ] || [ -z "$API_DOC" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Error: Missing required arguments"
  echo "Use --help for usage information"
  exit 1
fi

echo "🔪 Splitting OpenAPI document..."
echo "Provider: $PROVIDER_NAME"
echo "API Doc: $API_DOC"
echo "Output Directory: $OUTPUT_DIR"
echo "Service Discriminator: $SVC_DISCRIMINATOR"

# Build command arguments
ARGS=("--provider-name" "$PROVIDER_NAME" "--api-doc" "$API_DOC" "--output-dir" "$OUTPUT_DIR" "--svc-discriminator" "$SVC_DISCRIMINATOR")

if [ -n "$EXCLUDE" ]; then
  ARGS+=("--exclude" "$EXCLUDE")
  echo "Excluding: $EXCLUDE"
fi

if [ "$SVC_NAME_OVERRIDES" != "{}" ]; then
  ARGS+=("--svc-name-overrides" "$SVC_NAME_OVERRIDES")
  echo "Service Name Overrides: $SVC_NAME_OVERRIDES"
fi

if [ "$OVERWRITE" = true ]; then
  ARGS+=("--overwrite")
  echo "Overwrite: Yes"
fi

if [ "$VERBOSE" = true ]; then
  ARGS+=("--verbose")
  echo "Verbose: Yes"
fi

# Run the Node.js script with arguments
node --experimental-modules "$SCRIPT_DIR/split.mjs" "${ARGS[@]}"

# Check if command succeeded
if [ $? -ne 0 ]; then
    echo "❌ Split operation failed"
    exit 1
fi

echo "✅ Split operation completed successfully"