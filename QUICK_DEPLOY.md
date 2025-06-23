# ⚡ Быстрое развертывание MemGame

## 🚀 Для нового сервера (первый раз)

```bash
# 1. Подготовка сервера
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER && exit
# Перелогиньтесь на сервер

# 2. Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. Клонирование проекта
cd /opt
sudo git clone YOUR_REPO_URL memgame
sudo chown -R $USER:$USER /opt/memgame
cd /opt/memgame

# 4. Настройка окружения
cp env.production.example .env
nano .env  # Заполните переменные!

# 5. SSL сертификаты
# Вариант A: У вас уже есть teremok_space.crt и teremok_space.key
make ssl-teremok

# Вариант B: Другие пользовательские сертификаты  
make ssl-install CERT_FILE=/path/to/your/cert.crt KEY_FILE=/path/to/your/key.key

# Вариант C: Самоподписанные (для теста)
mkdir -p ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem -out ssl/cert.pem \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=MemGame/CN=yourdomain.com"

# 6. Развертывание
make deploy
```

## 🔄 Обновление (уже работающий сервер)

```bash
cd /opt/memgame
git pull origin main
make prod-build
make prod-up
```

## ⚙️ Основные команды

```bash
# Статус сервисов
make prod-status

# Логи
make prod-logs

# Backup базы данных
make prod-backup

# Консоль Rails
make prod-console

# Перезапуск
make prod-down && make prod-up

# Мониторинг
make monitor
```

## 🛑 Аварийное восстановление

```bash
# Остановить все
make prod-down

# Восстановить из backup
make prod-restore BACKUP_FILE=backups/backup_YYYYMMDD_HHMMSS.sql.gz

# Запустить заново
make prod-up
```

## 📝 Переменные .env (обязательные)

```bash
# Сгенерируйте безопасные значения:
DB_PASSWORD=$(openssl rand -base64 32)
RAILS_MASTER_KEY=$(openssl rand -hex 64)  
SECRET_KEY_BASE=$(openssl rand -hex 64)

# Укажите ваш домен:
DOMAIN=yourdomain.com
LETSENCRYPT_EMAIL=your@email.com
```

## 🔒 SSL сертификаты

### Let's Encrypt (автоматические)
```bash
# Получить реальные SSL сертификаты
make ssl-cert DOMAIN=yourdomain.com LETSENCRYPT_EMAIL=your@email.com

# Обновить сертификаты
make ssl-renew
```

### Пользовательские сертификаты
```bash
# Быстрая установка Teremok сертификатов (если файлы уже в ssl/)
make ssl-teremok

# Установить другие сертификаты
make ssl-install CERT_FILE=/path/to/cert.crt KEY_FILE=/path/to/key.key

# Проверить сертификаты
make ssl-check

# Обновить сертификаты Teremok
make ssl-update CERT_FILE=ssl/teremok_space.crt KEY_FILE=ssl/teremok_space.key
```

## 🎯 Проверка работы

- Health check: `curl https://yourdomain.com/health`
- Основной сайт: `https://yourdomain.com`
- Логи в реальном времени: `make prod-logs`

## ☎️ Поддержка

При проблемах:
1. Проверьте логи: `make prod-logs`
2. Статус контейнеров: `make prod-status`
3. Проверьте конфигурацию: `cat .env`
4. Перезапустите: `make prod-down && make prod-up` 