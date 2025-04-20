import { replaceInFileSync } from 'replace-in-file';
import { readdirSync } from 'fs';
import { join } from 'path';

const assetsDir = join(process.cwd(), 'dist', 'assets');
const files = readdirSync(assetsDir);
const cssFile = files.find(f => f.endsWith('.css'));
const jsFile = files.find(f => f.endsWith('.js'));

if (!cssFile || !jsFile) {
    console.error('Error: could not find .js and .css in dist/assets');
    process.exit(1);
}

replaceInFileSync({
    files: 'dist/**/*.html',
    from: /<!-- favicon\+css\+js -->/g,
    to: `<link href='/favicon' rel='icon' type='image/avif'><link rel='stylesheet' crossorigin href='/assets/${cssFile}'><link href='/fonts/Inter-VariableFont_opsz,wght.woff2' as='font' rel='preload' type='font/woff2' crossorigin='anonymous'><link href='/fonts/Inter-Italic-VariableFont_opsz,wght.woff2' as='font' rel='preload' type='font/woff2' crossorigin='anonymous'><script type='module' crossorigin src='/assets/${jsFile}'></script>`
});
