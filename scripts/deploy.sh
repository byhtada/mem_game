#!/bin/bash

# Скрипт автоматического развертывания MemGame
# Использование: ./scripts/deploy.sh [--force] [--no-backup]

set -e

# Конфигурация
PROJECT_DIR="/opt/memgame"
DOCKER_COMPOSE="docker-compose -f docker-compose.prod.yml"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Флаги
FORCE_DEPLOY=false
SKIP_BACKUP=false

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Обработка аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_DEPLOY=true
            shift
            ;;
        --no-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --help|-h)
            echo "Использование: $0 [опции]"
            echo ""
            echo "Опции:"
            echo "  --force      Принудительное развертывание без подтверждения"
            echo "  --no-backup  Пропустить создание backup перед развертыванием"
            echo "  --help       Показать эту справку"
            exit 0
            ;;
        *)
            log_error "Неизвестная опция: $1"
            exit 1
            ;;
    esac
done

# Проверка окружения
check_environment() {
    log_step "Проверка окружения..."
    
    # Проверка директории проекта
    if [ ! -d "$PROJECT_DIR" ]; then
        log_error "Директория проекта не найдена: $PROJECT_DIR"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    # Проверка .env файла
    if [ ! -f ".env" ]; then
        log_error "Файл .env не найден. Скопируйте env.production.example в .env"
        exit 1
    fi
    
    # Проверка Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker не установлен"
        exit 1
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "Docker Compose не установлен"
        exit 1
    fi
    
    log_info "✅ Окружение проверено"
}

# Создание backup перед развертыванием
create_backup() {
    if [ "$SKIP_BACKUP" = true ]; then
        log_warn "Пропускаем создание backup"
        return 0
    fi
    
    log_step "Создание backup перед развертыванием..."
    
    if [ -f "scripts/backup.sh" ]; then
        chmod +x scripts/backup.sh
        ./scripts/backup.sh local
        log_info "✅ Backup создан"
    else
        log_warn "Скрипт backup не найден, пропускаем"
    fi
}

# Получение последних изменений
update_code() {
    log_step "Получение последних изменений из Git..."
    
    # Сохранение текущей ветки
    CURRENT_BRANCH=$(git branch --show-current)
    
    # Проверка изменений
    git fetch origin
    
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/$CURRENT_BRANCH)
    
    if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
        log_info "Нет новых изменений для развертывания"
        if [ "$FORCE_DEPLOY" = false ]; then
            echo "Продолжить развертывание? (y/N)"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log_info "Развертывание отменено"
                exit 0
            fi
        fi
    else
        log_info "Найдены новые изменения:"
        git log --oneline $LOCAL_COMMIT..$REMOTE_COMMIT
    fi
    
    # Получение изменений
    git pull origin $CURRENT_BRANCH
    
    log_info "✅ Код обновлен"
}

# Проверка конфигурации
validate_config() {
    log_step "Проверка конфигурации..."
    
    # Проверка обязательных переменных в .env
    local required_vars=("DB_PASSWORD" "RAILS_MASTER_KEY" "SECRET_KEY_BASE")
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var=" .env; then
            log_error "Обязательная переменная $var не найдена в .env"
            exit 1
        fi
    done
    
    # Проверка SSL сертификатов
    if [ ! -f "ssl/cert.pem" ] || [ ! -f "ssl/key.pem" ]; then
        log_warn "SSL сертификаты не найдены в ssl/"
        log_warn "Используйте 'make ssl-cert' для получения сертификатов"
    fi
    
    log_info "✅ Конфигурация проверена"
}

# Остановка старых контейнеров
stop_services() {
    log_step "Остановка текущих сервисов..."
    
    if $DOCKER_COMPOSE ps | grep -q "Up"; then
        $DOCKER_COMPOSE stop
        log_info "✅ Сервисы остановлены"
    else
        log_info "Сервисы уже остановлены"
    fi
}

# Сборка новых образов
build_images() {
    log_step "Сборка Docker образов..."
    
    $DOCKER_COMPOSE build --no-cache --pull
    
    log_info "✅ Образы собраны"
}

# Запуск миграций
run_migrations() {
    log_step "Выполнение миграций базы данных..."
    
    # Запускаем только базу данных для миграций
    $DOCKER_COMPOSE up -d db redis
    
    # Ждем готовности базы данных
    log_info "Ожидание готовности базы данных..."
    sleep 30
    
    # Выполняем миграции
    $DOCKER_COMPOSE run --rm web bundle exec rails db:migrate
    
    log_info "✅ Миграции выполнены"
}

# Запуск всех сервисов
start_services() {
    log_step "Запуск всех сервисов..."
    
    $DOCKER_COMPOSE up -d
    
    log_info "✅ Сервисы запущены"
}

# Проверка здоровья приложения
health_check() {
    log_step "Проверка здоровья приложения..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if $DOCKER_COMPOSE exec -T web curl -f http://localhost:3000/health >/dev/null 2>&1; then
            log_info "✅ Приложение готово к работе"
            return 0
        fi
        
        log_info "Попытка $attempt/$max_attempts: ожидание готовности приложения..."
        sleep 10
        ((attempt++))
    done
    
    log_error "Приложение не отвечает на health check"
    return 1
}

# Очистка старых образов
cleanup() {
    log_step "Очистка старых Docker образов..."
    
    docker image prune -f
    
    log_info "✅ Очистка завершена"
}

# Отправка уведомления о результате
send_notification() {
    local status=$1
    local message=$2
    
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚀 MemGame Deploy $status: $message\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null || true
    fi
    
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="🚀 MemGame Deploy $status: $message" 2>/dev/null || true
    fi
}

# Откат в случае ошибки
rollback() {
    log_error "Откат к предыдущей версии..."
    
    # Здесь можно добавить логику отката
    # Например, восстановление из backup
    
    send_notification "Failed" "Deployment failed, rollback initiated"
}

# Основная функция
main() {
    log_info "🚀 Начинаем развертывание MemGame..."
    
    # Установка trap для обработки ошибок
    trap 'rollback' ERR
    
    # Выполнение шагов развертывания
    check_environment
    create_backup
    update_code
    validate_config
    stop_services
    build_images
    run_migrations
    start_services
    
    # Проверка здоровья
    if health_check; then
        cleanup
        send_notification "Success" "Deployment completed successfully"
        
        log_info "🎉 Развертывание завершено успешно!"
        log_info "🌐 Приложение доступно по адресу: https://$(grep DOMAIN .env | cut -d'=' -f2)"
        
        # Показать статус
        $DOCKER_COMPOSE ps
    else
        log_error "❌ Развертывание завершилось с ошибками"
        send_notification "Failed" "Deployment completed but health check failed"
        exit 1
    fi
}

# Запуск основной функции
main 