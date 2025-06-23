# 🚀 Инструкция по развертыванию MemGame на VPS

## 📋 Требования к серверу

- **ОС**: Ubuntu 20.04+ или CentOS 7+
- **RAM**: Минимум 2GB, рекомендуется 4GB+
- **CPU**: 2+ ядра
- **Диск**: Минимум 20GB SSD
- **Docker**: версия 20.10+
- **Docker Compose**: версия 2.0+

## 🛠 Подготовка сервера

### 1. Обновление системы

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

### 2. Установка Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# CentOS/RHEL
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### 3. Установка Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 4. Установка Git

```bash
# Ubuntu/Debian
sudo apt install -y git

# CentOS/RHEL
sudo yum install -y git
```

## 📥 Развертывание приложения

### 1. Клонирование репозитория

```bash
cd /opt
sudo git clone https://your-repository-url.git memgame
sudo chown -R $USER:$USER /opt/memgame
cd /opt/memgame
```

### 2. Настройка переменных окружения

```bash
# Копируем пример и редактируем
cp env.production.example .env
nano .env
```

**Обязательно заполните следующие переменные:**

```bash
# Сгенерируйте безопасные пароли и ключи
DB_PASSWORD=$(openssl rand -base64 32)
RAILS_MASTER_KEY=$(openssl rand -hex 64)
SECRET_KEY_BASE=$(openssl rand -hex 64)

# Укажите ваш домен
DOMAIN=yourdomain.com
LETSENCRYPT_EMAIL=your_email@domain.com
```

### 3. Создание директорий

```bash
# Создаем необходимые директории
mkdir -p ssl backups certbot/www certbot/conf logs

# Устанавливаем правильные права
chmod 755 ssl backups certbot logs
```

### 4. Получение SSL сертификатов

#### Вариант A: Let's Encrypt (рекомендуется)

```bash
# Временно запускаем nginx без SSL для получения сертификатов
docker-compose -f docker-compose.prod.yml up -d nginx

# Получаем сертификаты
docker-compose -f docker-compose.prod.yml --profile certbot run --rm certbot \
  certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email $LETSENCRYPT_EMAIL \
  --agree-tos \
  --no-eff-email \
  -d $DOMAIN

# Копируем сертификаты в правильное место
sudo cp certbot/conf/live/$DOMAIN/fullchain.pem ssl/cert.pem
sudo cp certbot/conf/live/$DOMAIN/privkey.pem ssl/key.pem

# Останавливаем временный nginx
docker-compose -f docker-compose.prod.yml down
```

#### Вариант B: Самоподписанные сертификаты (для тестирования)

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=MemGame/CN=$DOMAIN"
```

### 5. Настройка nginx конфигурации

```bash
# Замените доменное имя в nginx.conf
sed -i "s/server_name _;/server_name $DOMAIN;/g" nginx.conf
```

### 6. Запуск приложения

```bash
# Сборка и запуск всех сервисов
make prod-build
make prod-up

# Или вручную:
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

### 7. Проверка работы

```bash
# Проверяем статус контейнеров
docker-compose -f docker-compose.prod.yml ps

# Смотрим логи
docker-compose -f docker-compose.prod.yml logs -f

# Проверяем доступность
curl -I https://$DOMAIN
```

## 🔧 Обслуживание

### Обновление приложения

```bash
cd /opt/memgame
git pull origin main
make prod-build
docker-compose -f docker-compose.prod.yml up -d --force-recreate
```

### Резервное копирование базы данных

```bash
# Создание бэкапа
docker-compose -f docker-compose.prod.yml exec db pg_dump -U memgame memgame_production > backups/backup_$(date +%Y%m%d_%H%M%S).sql

# Автоматическое резервное копирование (добавить в cron)
echo "0 2 * * * cd /opt/memgame && docker-compose -f docker-compose.prod.yml exec -T db pg_dump -U memgame memgame_production > backups/backup_\$(date +\%Y\%m\%d_\%H\%M\%S).sql" | sudo crontab -
```

### Восстановление из бэкапа

```bash
# Остановка приложения
docker-compose -f docker-compose.prod.yml stop web sidekiq

# Восстановление
cat backups/backup_YYYYMMDD_HHMMSS.sql | docker-compose -f docker-compose.prod.yml exec -T db psql -U memgame -d memgame_production

# Запуск приложения
docker-compose -f docker-compose.prod.yml start web sidekiq
```

### Просмотр логов

```bash
# Все логи
docker-compose -f docker-compose.prod.yml logs -f

# Логи конкретного сервиса
docker-compose -f docker-compose.prod.yml logs -f web
docker-compose -f docker-compose.prod.yml logs -f sidekiq
docker-compose -f docker-compose.prod.yml logs -f nginx

# Логи Rails
docker-compose -f docker-compose.prod.yml exec web tail -f log/production.log
```

### Обновление SSL сертификатов

```bash
# Продление сертификатов Let's Encrypt
docker-compose -f docker-compose.prod.yml --profile certbot run --rm certbot renew

# Копирование обновленных сертификатов
sudo cp certbot/conf/live/$DOMAIN/fullchain.pem ssl/cert.pem
sudo cp certbot/conf/live/$DOMAIN/privkey.pem ssl/key.pem

# Перезапуск nginx
docker-compose -f docker-compose.prod.yml restart nginx

# Автоматическое обновление (добавить в cron)
echo "0 12 * * * cd /opt/memgame && docker-compose -f docker-compose.prod.yml --profile certbot run --rm certbot renew --quiet && sudo cp certbot/conf/live/$DOMAIN/fullchain.pem ssl/cert.pem && sudo cp certbot/conf/live/$DOMAIN/privkey.pem ssl/key.pem && docker-compose -f docker-compose.prod.yml restart nginx" | sudo crontab -
```

## 🔒 Безопасность

### 1. Настройка файрвола

```bash
# Ubuntu/Debian (ufw)
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# CentOS/RHEL (firewalld)
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 2. Отключение root SSH

```bash
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 3. Автоматические обновления безопасности

```bash
# Ubuntu/Debian
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# CentOS/RHEL
sudo yum install -y yum-cron
sudo systemctl enable yum-cron
sudo systemctl start yum-cron
```

## 📊 Мониторинг

### Основные команды для мониторинга

```bash
# Использование ресурсов
docker stats

# Дисковое пространство
df -h
du -sh /opt/memgame/*

# Состояние сервисов
docker-compose -f docker-compose.prod.yml ps
systemctl status docker

# Проверка соединений
netstat -tulpn | grep :80
netstat -tulpn | grep :443
```

### Настройка алертов

Для мониторинга рекомендуется настроить:
- **Uptime Robot** или **Pingdom** для проверки доступности
- **New Relic** или **DataDog** для APM
- **Sentry** для отслеживания ошибок

## 🚨 Устранение неполадок

### Часто встречающиеся проблемы

1. **Контейнер не запускается**
   ```bash
   docker-compose -f docker-compose.prod.yml logs servicename
   ```

2. **База данных недоступна**
   ```bash
   docker-compose -f docker-compose.prod.yml exec db psql -U memgame -d memgame_production
   ```

3. **SSL сертификаты недействительны**
   ```bash
   openssl x509 -in ssl/cert.pem -text -noout
   ```

4. **Нехватка дискового пространства**
   ```bash
   docker system prune -af
   docker volume prune -f
   ```

### Контакты для поддержки

- **Email**: support@yourcompany.com
- **Telegram**: @yourusername
- **GitHub Issues**: https://github.com/your-repo/issues

---

## 📝 Чеклист развертывания

- [ ] Сервер обновлен и настроен
- [ ] Docker и Docker Compose установлены
- [ ] Репозиторий склонирован
- [ ] Переменные окружения настроены
- [ ] SSL сертификаты получены
- [ ] Nginx конфигурация обновлена
- [ ] Приложение запущено
- [ ] Файрвол настроен
- [ ] Резервное копирование настроено
- [ ] Мониторинг настроен
- [ ] Домен направлен на сервер

**🎉 Поздравляем! Ваше приложение развернуто в продакшене!** 