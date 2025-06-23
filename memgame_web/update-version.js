const fs = require('fs');
const path = require('path');

// Функция для обновления версии в HTML файле
function updateVersions() {
    const htmlPath = path.join(__dirname, 'index.html');
    const buildTime = Date.now();
    
    // Читаем HTML файл
    let htmlContent = fs.readFileSync(htmlPath, 'utf8');
    
    // Обновляем версии CSS
    htmlContent = htmlContent.replace(
        /css\/style\.css\?v=[\d.]+/g,
        `css/style.css?v=${buildTime}`
    );
    
    // Обновляем версии изображений навигации
    htmlContent = htmlContent.replace(
        /\.svg\?v[\d.]+/g,
        `.svg?v=${buildTime}`
    );
    
    // Записываем обновленный файл
    fs.writeFileSync(htmlPath, htmlContent, 'utf8');
    
    console.log(`✅ Версии обновлены: ${buildTime}`);
}

// Запускаем обновление
updateVersions(); 