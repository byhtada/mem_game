const fs = require('fs');
const path = require('path');

// Функция для увеличения версии CSS
function bumpCssVersion() {
    const htmlPath = path.join(__dirname, 'index.html');
    
    // Читаем HTML файл
    let htmlContent = fs.readFileSync(htmlPath, 'utf8');
    
    // Находим текущую версию CSS
    const cssVersionMatch = htmlContent.match(/css\/style\.css\?v=([\d.]+)/);
    
    if (cssVersionMatch) {
        const currentVersion = cssVersionMatch[1];
        const versionParts = currentVersion.split('.');
        
        // Увеличиваем последнюю часть версии
        const lastPart = parseInt(versionParts[versionParts.length - 1]) + 1;
        versionParts[versionParts.length - 1] = lastPart.toString();
        
        const newVersion = versionParts.join('.');
        
        // Обновляем версию в HTML
        htmlContent = htmlContent.replace(
            new RegExp(`css/style\\.css\\?v=${currentVersion.replace(/\./g, '\\.')}`),
            `css/style.css?v=${newVersion}`
        );
        
        // Записываем обновленный файл
        fs.writeFileSync(htmlPath, htmlContent, 'utf8');
        
        console.log(`✅ CSS версия обновлена: ${currentVersion} → ${newVersion}`);
    } else {
        console.log('❌ Версия CSS не найдена в HTML файле');
    }
}

// Запускаем обновление
bumpCssVersion(); 