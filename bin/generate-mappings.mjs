#!/usr/bin/env node

import { providerdev } from '@stackql/provider-utils';

async function generateMappings() {
  // Get command line arguments
  const args = process.argv.slice(2);
  const getArg = (flag) => {
    const index = args.indexOf(flag);
    return index !== -1 ? args[index + 1] : null;
  };

  const providerName = getArg('--provider-name');
  const inputDir = getArg('--input-dir');
  const outputDir = getArg('--output-dir');
  const verbose = args.includes('--verbose');

  if (!providerName || !inputDir || !outputDir) {
    console.error('Error: Missing required arguments');
    console.error('Usage: node generate-mappings.mjs --provider-name NAME --input-dir DIR --output-dir DIR [--verbose]');
    process.exit(1);
  }

  try {
    console.log(`Analyzing OpenAPI specs for provider: ${providerName}`);
    console.log(`Input directory: ${inputDir}`);
    console.log(`Output directory: ${outputDir}`);

    const result = await providerdev.analyze({
      inputDir,
      outputDir,
      verbose
    });
    
    console.log('Analysis completed successfully:', result);
  } catch (error) {
    console.error('Error analyzing OpenAPI specs:', error);
    process.exit(1);
  }
}

generateMappings();