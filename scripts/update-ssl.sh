#!/bin/bash

# Скрипт обновления пользовательского SSL сертификата
# Использование: ./scripts/update-ssl.sh /path/to/new/cert.crt /path/to/new/private.key

set -e

# Конфигурация
PROJECT_DIR="/opt/memgame"
SSL_DIR="$PROJECT_DIR/ssl"
DOCKER_COMPOSE="docker-compose -f docker-compose.prod.yml"

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка аргументов
if [ $# -ne 2 ]; then
    echo "Использование: $0 <certificate_file> <private_key_file>"
    echo ""
    echo "Пример:"
    echo "  $0 /path/to/new_cert.crt /path/to/new_key.key"
    echo "  $0 /path/to/combined_cert.pem /path/to/private.key"
    exit 1
fi

CERT_FILE="$1"
KEY_FILE="$2"

# Проверка существования файлов
check_files() {
    log_info "Проверка файлов сертификата..."
    
    if [ ! -f "$CERT_FILE" ]; then
        log_error "Файл сертификата не найден: $CERT_FILE"
        exit 1
    fi
    
    if [ ! -f "$KEY_FILE" ]; then
        log_error "Файл приватного ключа не найден: $KEY_FILE"
        exit 1
    fi
    
    log_info "✅ Файлы найдены"
}

# Проверка валидности сертификата
validate_certificate() {
    log_info "Проверка валидности сертификата..."
    
    # Проверка формата сертификата
    if ! openssl x509 -in "$CERT_FILE" -noout 2>/dev/null; then
        log_error "Некорректный формат сертификата"
        exit 1
    fi
    
    # Проверка формата ключа
    if ! openssl rsa -in "$KEY_FILE" -check -noout 2>/dev/null; then
        log_error "Некорректный формат приватного ключа"
        exit 1
    fi
    
    # Проверка соответствия ключа и сертификата
    cert_modulus=$(openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5)
    key_modulus=$(openssl rsa -noout -modulus -in "$KEY_FILE" | openssl md5)
    
    if [ "$cert_modulus" != "$key_modulus" ]; then
        log_error "Приватный ключ не соответствует сертификату"
        exit 1
    fi
    
    # Информация о сертификате
    log_info "Информация о сертификате:"
    openssl x509 -in "$CERT_FILE" -noout -subject -issuer -dates
    
    log_info "✅ Сертификат валиден"
}

# Резервное копирование текущих сертификатов
backup_current_certs() {
    log_info "Создание резервной копии текущих сертификатов..."
    
    if [ -f "$SSL_DIR/cert.pem" ] && [ -f "$SSL_DIR/key.pem" ]; then
        backup_dir="$SSL_DIR/backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        
        cp "$SSL_DIR/cert.pem" "$backup_dir/"
        cp "$SSL_DIR/key.pem" "$backup_dir/"
        
        log_info "✅ Резервная копия создана: $backup_dir"
    else
        log_warn "Текущие сертификаты не найдены, пропускаем backup"
    fi
}

# Установка новых сертификатов
install_new_certs() {
    log_info "Установка новых сертификатов..."
    
    # Создание SSL директории если не существует
    mkdir -p "$SSL_DIR"
    
    # Копирование новых сертификатов
    cp "$CERT_FILE" "$SSL_DIR/cert.pem"
    cp "$KEY_FILE" "$SSL_DIR/key.pem"
    
    # Установка правильных прав доступа
    chmod 644 "$SSL_DIR/cert.pem"
    chmod 600 "$SSL_DIR/key.pem"
    
    log_info "✅ Новые сертификаты установлены"
}

# Перезапуск Nginx
restart_nginx() {
    log_info "Перезапуск Nginx..."
    
    cd "$PROJECT_DIR"
    
    if $DOCKER_COMPOSE ps nginx | grep -q "Up"; then
        $DOCKER_COMPOSE restart nginx
        log_info "✅ Nginx перезапущен"
    else
        log_warn "Nginx не запущен, запускаем все сервисы..."
        $DOCKER_COMPOSE up -d
    fi
}

# Проверка работы SSL
test_ssl() {
    log_info "Проверка работы SSL..."
    
    # Ждем немного для перезапуска Nginx
    sleep 5
    
    # Получаем домен из .env
    if [ -f "$PROJECT_DIR/.env" ]; then
        domain=$(grep "^DOMAIN=" "$PROJECT_DIR/.env" | cut -d'=' -f2)
        
        if [ -n "$domain" ]; then
            log_info "Тестирование SSL для домена: $domain"
            
            # Проверка SSL соединения
            if echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | grep -q "Verify return code: 0"; then
                log_info "✅ SSL работает корректно"
            else
                log_warn "SSL может работать некорректно, проверьте вручную"
            fi
        else
            log_warn "Домен не найден в .env, пропускаем автоматическую проверку"
        fi
    else
        log_warn "Файл .env не найден, пропускаем автоматическую проверку"
    fi
    
    log_info "Проверьте SSL вручную: curl -I https://yourdomain.com"
}

# Отправка уведомления
send_notification() {
    local status=$1
    local message=$2
    
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
        
        if [ -n "$SLACK_WEBHOOK_URL" ]; then
            curl -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"🔐 MemGame SSL Update $status: $message\"}" \
                "$SLACK_WEBHOOK_URL" 2>/dev/null || true
        fi
        
        if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                -d chat_id="$TELEGRAM_CHAT_ID" \
                -d text="🔐 MemGame SSL Update $status: $message" 2>/dev/null || true
        fi
    fi
}

# Основная функция
main() {
    log_info "🔐 Обновление SSL сертификата для MemGame..."
    
    check_files
    validate_certificate
    backup_current_certs
    install_new_certs
    restart_nginx
    test_ssl
    
    send_notification "Success" "SSL certificate updated successfully"
    
    log_info "🎉 SSL сертификат обновлен успешно!"
    log_info "📋 Что было сделано:"
    echo "  • Проверена валидность нового сертификата"
    echo "  • Создана резервная копия старого сертификата"
    echo "  • Установлен новый сертификат"
    echo "  • Перезапущен Nginx"
    echo "  • Протестирована работа SSL"
    echo
    log_info "🌐 Проверьте работу: https://yourdomain.com"
}

# Запуск
main 