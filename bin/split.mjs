#!/usr/bin/env node

import { providerdev } from '@stackql/provider-utils';

async function splitOpenApi() {
  // Get command line arguments
  const args = process.argv.slice(2);
  const getArg = (flag) => {
    const index = args.indexOf(flag);
    return index !== -1 ? args[index + 1] : null;
  };

  const providerName = getArg('--provider-name');
  const apiDoc = getArg('--api-doc');
  const outputDir = getArg('--output-dir');
  const svcDiscriminator = getArg('--svc-discriminator') || 'tag';
  const exclude = getArg('--exclude') || '';
  const overwrite = args.includes('--overwrite');
  const verbose = args.includes('--verbose');
  const svcNameOverridesStr = getArg('--svc-name-overrides') || '{}';
  
  let svcNameOverrides = {};
  try {
    svcNameOverrides = JSON.parse(svcNameOverridesStr);
  } catch (err) {
    console.error('Error parsing service name overrides JSON:', err.message);
    console.error('Please ensure the JSON format is correct');
    process.exit(1);
  }

  if (!providerName || !apiDoc || !outputDir) {
    console.error('Error: Missing required arguments');
    console.error('Usage: node split.mjs --provider-name NAME --api-doc PATH --output-dir DIR [--svc-discriminator tag|path] [--exclude LIST] [--svc-name-overrides JSON] [--overwrite] [--verbose]');
    process.exit(1);
  }

  try {
    console.log(`Splitting OpenAPI doc for provider: ${providerName}`);
    console.log(`API Doc: ${apiDoc}`);
    console.log(`Output directory: ${outputDir}`);
    console.log(`Service Discriminator: ${svcDiscriminator}`);
    
    if (exclude) {
      console.log(`Excluding: ${exclude}`);
    }
    
    const numOverrides = Object.keys(svcNameOverrides).length;
    if (numOverrides > 0) {
      console.log(`Service name overrides: ${numOverrides} mappings`);
      if (verbose) {
        console.log('Override mappings:');
        for (const [original, newName] of Object.entries(svcNameOverrides)) {
          console.log(`  ${original} -> ${newName}`);
        }
      }
    }

    const result = await providerdev.split({
      apiDoc,
      providerName,
      outputDir,
      svcDiscriminator,
      exclude,
      overwrite,
      verbose,
      svcNameOverrides
    });
    
    console.log('Split operation completed successfully:', result);
  } catch (error) {
    console.error('Error splitting OpenAPI doc:', error);
    process.exit(1);
  }
}

splitOpenApi();