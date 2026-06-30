const fs = require('fs');
const path = require('path');
const postcss = require('postcss');
const importPlugin = require('postcss-import');

// Use process.cwd() — the PowerShell script does Push-Location to the project dir
const baseDir = process.cwd();

async function build() {
    const inputFile = path.join(baseDir, 'themes/demius/assets/css/main.css');
    const css = fs.readFileSync(inputFile, 'utf8');
    const result = await postcss([
        importPlugin({
            root: path.join(baseDir, 'themes/demius/assets/css'),
            path: [
                path.join(baseDir, 'themes/demius/assets/css'),
                path.join(baseDir, 'assets/css')
            ]
        })
    ]).process(css, { from: inputFile });
    const outDir = path.join(baseDir, 'static/css');
    fs.mkdirSync(outDir, { recursive: true });
    fs.writeFileSync(path.join(outDir, 'main.css'), result.css);
    console.log('  CSS built: ' + (result.css.length / 1024).toFixed(1) + ' KB');
}

build().catch(e => { console.error('  CSS build FAILED: ' + e.message); process.exit(1); });
