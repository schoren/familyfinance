import fs from 'fs-extra';
import path from 'path';
import dotenv from 'dotenv';

// Load .env
dotenv.config();

const __dirname = path.dirname(new URL(import.meta.url).pathname);
const SRC_DIR = __dirname;
const DIST_DIR = path.join(__dirname, 'dist');

const TRANSLATIONS = JSON.parse(fs.readFileSync(path.join(SRC_DIR, 'translations.json'), 'utf-8'));

const ENV_VARS = {
  APP_URL: process.env.APP_URL || '/app',
  GITHUB_REPO_URL: process.env.GITHUB_REPO_URL || 'https://github.com/schoren/keda',
  APP_STORE_URL: process.env.APP_STORE_URL || '#',
  PLAY_STORE_URL: process.env.PLAY_STORE_URL || '#',
  CONTACT_EMAIL: process.env.CONTACT_EMAIL || 'info@getkeda.app',
  DEMO_VIDEO_URL: process.env.DEMO_VIDEO_URL || '../assets/demo.webm'
};

async function build() {
  console.log('Building landing page...');

  // Ensure dist exists and is empty
  await fs.emptyDir(DIST_DIR);

  const templates = ['index.html', 'privacy.html', 'terms.html'];

  for (const lang of Object.keys(TRANSLATIONS)) {
    console.log(`Generating ${lang} version...`);
    const langDir = path.join(DIST_DIR, lang);
    await fs.ensureDir(langDir);

    for (const templateName of templates) {
      const templatePath = path.join(SRC_DIR, templateName);
      if (!await fs.pathExists(templatePath)) continue;

      let content = await fs.readFile(templatePath, 'utf-8');

      // Replace translations
      for (const [key, value] of Object.entries(TRANSLATIONS[lang])) {
        const regex = new RegExp(`{{${key}}}`, 'g');
        content = content.replace(regex, value);
      }

      // Replace env vars
      for (const [key, value] of Object.entries(ENV_VARS)) {
        const regex = new RegExp(`{{${key}}}`, 'g');
        content = content.replace(regex, value);
      }

      // Set lang attribute (handles both <html lang="es"> and <html lang="{{lang}}">)
      content = content.replace(/<html lang="[^"]*"/, `<html lang="${lang}"`);
      content = content.replace('{{lang}}', lang);

      await fs.writeFile(path.join(langDir, templateName), content);
    }
  }

  // Copy assets
  console.log('Copying assets...');
  await fs.copy(path.join(SRC_DIR, 'style.css'), path.join(DIST_DIR, 'style.css'));
  await fs.copy(path.join(SRC_DIR, 'script.js'), path.join(DIST_DIR, 'script.js'));
  await fs.copy(path.join(SRC_DIR, 'assets'), path.join(DIST_DIR, 'assets'));

  // Create root index.html with redirection
  console.log('Creating root redirector...');
  const redirectHtml = `
<!DOCTYPE html>
<html>
<head>
    <title>KEDA</title>
    <script>
        // Use saved preference or detect from browser
        var savedLang = localStorage.getItem('selected-lang');
        var path = window.location.pathname;
        var isLocalized = path.split('/').some(function(s) { return s === 'es' || s === 'en'; });
        
        if (!isLocalized) {
            var targetLang = savedLang;
            if (!targetLang) {
                var browserLang = navigator.language || navigator.userLanguage;
                targetLang = browserLang.startsWith('es') ? 'es' : 'en';
            }
            window.location.href = './' + targetLang + '/';
        }
    </script>
    <noscript>
        <meta http-equiv="refresh" content="0; url=./en/">
    </noscript>
</head>
<body>
    <p>Redirecting / Redireccionando...</p>
</body>
</html>
`;
  await fs.writeFile(path.join(DIST_DIR, 'index.html'), redirectHtml);

  console.log('Build complete!');
}

build().catch(err => {
  console.error('Build failed:', err);
  process.exit(1);
});
