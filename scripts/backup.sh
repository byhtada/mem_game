#!/bin/bash

# Скрипт автоматического резервного копирования MemGame
# Использование: ./scripts/backup.sh [local|s3]

set -e

# Конфигурация
BACKUP_DIR="/opt/memgame/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="memgame_backup_${DATE}.sql"
DOCKER_COMPOSE="docker-compose -f docker-compose.prod.yml"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав доступа
check_permissions() {
    if [ ! -w "$BACKUP_DIR" ]; then
        log_error "Нет прав записи в директорию $BACKUP_DIR"
        exit 1
    fi
}

# Создание backup директории
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    log_info "Директория backup создана: $BACKUP_DIR"
}

# Создание backup базы данных
create_database_backup() {
    log_info "Создание backup базы данных..."
    
    cd /opt/memgame
    
    if ! $DOCKER_COMPOSE exec -T db pg_dump -U memgame memgame_production > "$BACKUP_DIR/$BACKUP_FILE"; then
        log_error "Ошибка создания backup базы данных"
        exit 1
    fi
    
    # Проверка размера файла
    if [ ! -s "$BACKUP_DIR/$BACKUP_FILE" ]; then
        log_error "Backup файл пустой или не создан"
        exit 1
    fi
    
    # Сжатие backup
    gzip "$BACKUP_DIR/$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
    
    log_info "Backup создан: $BACKUP_DIR/$BACKUP_FILE"
    log_info "Размер файла: $(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)"
}

# Загрузка в S3 (опционально)
upload_to_s3() {
    if [ -z "$AWS_S3_BUCKET" ]; then
        log_warn "AWS_S3_BUCKET не установлен, пропускаем загрузку в S3"
        return 0
    fi
    
    log_info "Загрузка backup в S3..."
    
    if command -v aws >/dev/null 2>&1; then
        aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$AWS_S3_BUCKET/backups/"
        log_info "Backup загружен в S3: s3://$AWS_S3_BUCKET/backups/$BACKUP_FILE"
    else
        log_warn "AWS CLI не установлен, пропускаем загрузку в S3"
    fi
}

# Очистка старых backup
cleanup_old_backups() {
    log_info "Очистка старых backup (старше 30 дней)..."
    
    find "$BACKUP_DIR" -name "memgame_backup_*.sql.gz" -mtime +30 -delete
    
    log_info "Старые backup удалены"
}

# Отправка уведомления
send_notification() {
    local status=$1
    local message=$2
    
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🔧 MemGame Backup $status: $message\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null || true
    fi
    
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="🔧 MemGame Backup $status: $message" 2>/dev/null || true
    fi
}

# Основная функция
main() {
    local mode=${1:-local}
    
    log_info "Начинаем создание backup (режим: $mode)"
    
    # Проверки
    check_permissions
    create_backup_dir
    
    # Создание backup
    if create_database_backup; then
        log_info "✅ Backup базы данных создан успешно"
        
        # Загрузка в S3 если требуется
        if [ "$mode" = "s3" ]; then
            upload_to_s3
        fi
        
        # Очистка старых backup
        cleanup_old_backups
        
        # Уведомление об успехе
        send_notification "Success" "Backup created: $BACKUP_FILE"
        
        log_info "🎉 Backup процесс завершен успешно"
    else
        log_error "❌ Ошибка создания backup"
        send_notification "Failed" "Backup creation failed"
        exit 1
    fi
}

# Проверка аргументов
case "$1" in
    local|s3|"")
        main "$1"
        ;;
    --help|-h)
        echo "Использование: $0 [local|s3]"
        echo ""
        echo "  local  - Создать backup только локально (по умолчанию)"
        echo "  s3     - Создать backup и загрузить в S3"
        echo ""
        echo "Переменные окружения:"
        echo "  AWS_S3_BUCKET      - Bucket для загрузки backup"
        echo "  SLACK_WEBHOOK_URL  - URL для уведомлений в Slack"
        echo "  TELEGRAM_BOT_TOKEN - Токен Telegram бота"
        echo "  TELEGRAM_CHAT_ID   - ID чата для уведомлений"
        exit 0
        ;;
    *)
        log_error "Неизвестный аргумент: $1"
        echo "Используйте '$0 --help' для справки"
        exit 1
        ;;
esac 