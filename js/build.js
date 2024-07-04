const { build } = require('esbuild');

build({
    entryPoints: ['run.mjs'],
    bundle: true,
    platform: 'node',
    outfile: 'find_string_tokens.js',
    minify: true,
}).catch(() => process.exit(1));
