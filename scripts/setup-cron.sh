#!/bin/bash

# Скрипт настройки cron задач для MemGame
# Использование: ./scripts/setup-cron.sh

set -e

# Конфигурация
PROJECT_DIR="/opt/memgame"
BACKUP_SCRIPT="$PROJECT_DIR/scripts/backup.sh"
DEPLOY_SCRIPT="$PROJECT_DIR/scripts/deploy.sh"

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

# Проверка прав доступа
check_permissions() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Не запускайте этот скрипт от root"
        exit 1
    fi
    
    if [ ! -d "$PROJECT_DIR" ]; then
        log_error "Директория проекта не найдена: $PROJECT_DIR"
        exit 1
    fi
}

# Создание временного cron файла
create_cron_jobs() {
    local cron_file="/tmp/memgame_cron"
    
    log_info "Создание cron задач..."
    
    # Получаем текущие cron задачи
    crontab -l 2>/dev/null > "$cron_file" || touch "$cron_file"
    
    # Удаляем старые задачи MemGame (если есть)
    sed -i '/# MemGame/d' "$cron_file"
    
    # Добавляем новые задачи
    cat >> "$cron_file" << EOF

# MemGame - Ежедневный backup в 02:00
0 2 * * * cd $PROJECT_DIR && $BACKUP_SCRIPT local >/dev/null 2>&1

# MemGame - Обновление SSL сертификатов (каждый понедельник в 03:00)
0 3 * * 1 cd $PROJECT_DIR && make ssl-renew >/dev/null 2>&1

# MemGame - Очистка Docker (каждое воскресенье в 04:00)
0 4 * * 0 docker system prune -f >/dev/null 2>&1

# MemGame - Мониторинг дискового пространства (каждый час)
0 * * * * df -h | awk '\$5 > 80 {print "Диск заполнен на " \$5 ": " \$1}' | head -1

EOF
    
    log_info "Задачи добавлены в cron файл"
}

# Установка cron задач
install_cron_jobs() {
    local cron_file="/tmp/memgame_cron"
    
    log_info "Установка cron задач..."
    
    if crontab "$cron_file"; then
        log_info "✅ Cron задачи установлены успешно"
    else
        log_error "Ошибка установки cron задач"
        return 1
    fi
    
    # Удаляем временный файл
    rm -f "$cron_file"
}

# Показать установленные задачи
show_cron_jobs() {
    log_info "Установленные cron задачи:"
    echo
    crontab -l | grep -A 10 "# MemGame" || log_warn "Задачи MemGame не найдены"
}

# Настройка логирования cron
setup_cron_logging() {
    log_info "Настройка логирования cron..."
    
    # Создаем директорию для логов
    sudo mkdir -p /var/log/memgame
    sudo chown $USER:$USER /var/log/memgame
    
    # Добавляем в rsyslog конфигурацию (опционально)
    if [ -f /etc/rsyslog.conf ]; then
        if ! grep -q "memgame" /etc/rsyslog.conf; then
            echo "# MemGame cron logs" | sudo tee -a /etc/rsyslog.conf
            echo "cron.*    /var/log/memgame/cron.log" | sudo tee -a /etc/rsyslog.conf
            sudo systemctl restart rsyslog 2>/dev/null || true
        fi
    fi
    
    log_info "✅ Логирование настроено"
}

# Настройка ротации логов
setup_log_rotation() {
    log_info "Настройка ротации логов..."
    
    local logrotate_config="/etc/logrotate.d/memgame"
    
    sudo tee "$logrotate_config" > /dev/null << EOF
/var/log/memgame/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}

$PROJECT_DIR/log/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF
    
    log_info "✅ Ротация логов настроена"
}

# Тестирование backup скрипта
test_backup_script() {
    log_info "Тестирование backup скрипта..."
    
    if [ -f "$BACKUP_SCRIPT" ]; then
        chmod +x "$BACKUP_SCRIPT"
        
        # Тестовый запуск (только проверка синтаксиса)
        if bash -n "$BACKUP_SCRIPT"; then
            log_info "✅ Backup скрипт синтаксически корректен"
        else
            log_error "Ошибка в синтаксисе backup скрипта"
            return 1
        fi
    else
        log_error "Backup скрипт не найден: $BACKUP_SCRIPT"
        return 1
    fi
}

# Создание systemd таймеров (альтернатива cron)
create_systemd_timers() {
    log_info "Создание systemd таймеров (опционально)..."
    
    # Backup service
    sudo tee /etc/systemd/system/memgame-backup.service > /dev/null << EOF
[Unit]
Description=MemGame Database Backup
After=docker.service

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$BACKUP_SCRIPT local
EOF
    
    # Backup timer
    sudo tee /etc/systemd/system/memgame-backup.timer > /dev/null << EOF
[Unit]
Description=Run MemGame backup daily
Requires=memgame-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Включение и запуск таймера
    sudo systemctl daemon-reload
    sudo systemctl enable memgame-backup.timer
    sudo systemctl start memgame-backup.timer
    
    log_info "✅ Systemd таймеры созданы и запущены"
    log_info "Проверить статус: sudo systemctl status memgame-backup.timer"
}

# Основная функция
main() {
    log_info "🔧 Настройка cron задач для MemGame..."
    
    check_permissions
    test_backup_script
    create_cron_jobs
    install_cron_jobs
    setup_cron_logging
    setup_log_rotation
    show_cron_jobs
    
    echo
    log_info "🎉 Настройка cron завершена!"
    log_info "📋 Что было настроено:"
    echo "  • Ежедневный backup базы данных в 02:00"
    echo "  • Обновление SSL сертификатов каждый понедельник"
    echo "  • Очистка Docker каждое воскресенье"
    echo "  • Мониторинг дискового пространства каждый час"
    echo "  • Ротация логов"
    echo
    log_info "📊 Проверить задачи: crontab -l"
    log_info "📝 Логи cron: tail -f /var/log/cron"
    echo
    
    # Предложение создать systemd таймеры
    echo "Создать systemd таймеры как альтернативу cron? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        create_systemd_timers
    fi
}

# Проверка аргументов
case "$1" in
    --help|-h)
        echo "Скрипт настройки cron задач для MemGame"
        echo ""
        echo "Использование: $0"
        echo ""
        echo "Устанавливаемые задачи:"
        echo "  • Ежедневный backup базы данных"
        echo "  • Обновление SSL сертификатов"
        echo "  • Очистка Docker"
        echo "  • Мониторинг диска"
        echo ""
        echo "Опции:"
        echo "  --help, -h    Показать эту справку"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Неизвестная опция: $1"
        echo "Используйте '$0 --help' для справки"
        exit 1
        ;;
esac 