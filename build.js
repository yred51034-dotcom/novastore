const fs = require('node:fs');
const path = require('node:path');
const esbuild = require('esbuild');

async function build() {
  const root = __dirname;
  const outDir = path.join(root, 'www');
  fs.mkdirSync(outDir, { recursive: true });

  for (const file of ['index.html', 'supabase-config.js']) {
    const source = path.join(root, file);
    if (!fs.existsSync(source)) throw new Error(`Fichier requis absent : ${file}`);
    fs.copyFileSync(source, path.join(outDir, file));
  }

  await esbuild.build({
    entryPoints: [path.join(root, 'supabase-browser.js')],
    bundle: true,
    minify: true,
    platform: 'browser',
    format: 'iife',
    target: ['es2020'],
    outfile: path.join(outDir, 'supabase.min.js'),
  });

  const bundle = path.join(outDir, 'supabase.min.js');
  if (!fs.existsSync(bundle) || fs.statSync(bundle).size < 10000) {
    throw new Error('Bundle Supabase absent ou anormalement petit.');
  }
  const html = fs.readFileSync(path.join(outDir, 'index.html'), 'utf8');
  if (!html.includes('./supabase-config.js') || !html.includes('./supabase.min.js')) {
    throw new Error('Les scripts Supabase ne sont pas référencés dans index.html.');
  }
  console.log(`Build Nova Store terminé. Bundle Supabase : ${fs.statSync(bundle).size} octets.`);
}

build().catch((error) => {
  console.error('Échec du build Nova Store :', error);
  process.exit(1);
});
