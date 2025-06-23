#!/bin/bash

# Скрипт для автоматического отслеживания изменений JS файлов
# и пересборки фронтенда

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Запуск автоматического отслеживания изменений JS файлов...${NC}"
echo -e "${YELLOW}📁 Отслеживаемые папки: memgame_web/js/, memgame_web/css/, memgame_web/index.html${NC}"
echo -e "${YELLOW}⏹  Для остановки нажмите Ctrl+C${NC}"
echo ""

# Функция для пересборки
rebuild_frontend() {
    echo -e "${GREEN}🔄 Обнаружены изменения, пересобираем фронтенд...${NC}"
    make frontend-local
    echo -e "${GREEN}✅ Фронтенд пересобран!${NC}"
    echo -e "${BLUE}⏳ Продолжаем отслеживание...${NC}"
    echo ""
}

# Проверяем, доступен ли fswatch (macOS)
if command -v fswatch >/dev/null 2>&1; then
    echo -e "${GREEN}📡 Используем fswatch для отслеживания${NC}"
    fswatch -o memgame_web/js/ memgame_web/css/ memgame_web/index.html | while read f; do
        rebuild_frontend
    done
# Проверяем, доступен ли inotifywait (Linux)
elif command -v inotifywait >/dev/null 2>&1; then
    echo -e "${GREEN}📡 Используем inotifywait для отслеживания${NC}"
    inotifywait -m -r -e create,modify,delete memgame_web/js/ memgame_web/css/ memgame_web/index.html | while read f; do
        rebuild_frontend
    done
else
    # Fallback: простой polling
    echo -e "${YELLOW}⚠️  fswatch и inotifywait не найдены, используем простое отслеживание${NC}"
    echo -e "${YELLOW}📝 Установите fswatch для лучшей производительности: brew install fswatch${NC}"
    echo ""
    
    LAST_HASH=""
    
    while true; do
        # Вычисляем хэш всех JS, CSS файлов и HTML
        CURRENT_HASH=$(find memgame_web/js/ memgame_web/css/ memgame_web/index.html -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) -exec md5 {} \; 2>/dev/null | md5)
        
        if [ "$CURRENT_HASH" != "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
            rebuild_frontend
        fi
        
        LAST_HASH="$CURRENT_HASH"
        sleep 2
    done
fi 