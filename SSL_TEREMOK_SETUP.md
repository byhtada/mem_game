# 🔐 Быстрая настройка SSL для Teremok

У вас уже есть сертификаты в папке `/opt/memgame/ssl/`:
- `teremok_space.crt`
- `teremok_space.key`

## ⚡ Быстрый запуск

```bash
# Находясь в /opt/memgame
cd /opt/memgame

# Быстрая установка ваших сертификатов
make ssl-teremok

# Запуск приложения
make prod-up
```

## 🔍 Проверка

```bash
# Проверить, что сертификаты установлены правильно
make ssl-check

# Проверить статус сервисов
make prod-status

# Проверить SSL в браузере или curl
curl -I https://teremok.space
```

## 📁 Что происходит

Команда `make ssl-teremok` делает следующее:

1. Копирует `teremok_space.crt` → `cert.pem`
2. Копирует `teremok_space.key` → `key.pem`
3. Устанавливает правильные права доступа:
   - `cert.pem` - 644 (читается всеми)
   - `key.pem` - 600 (только владелец)

## 🔄 Обновление сертификатов

Когда понадобится обновить сертификаты:

```bash
# 1. Загрузите новые файлы в ssl/
scp new_teremok_space.crt root@server:/opt/memgame/ssl/teremok_space.crt
scp new_teremok_space.key root@server:/opt/memgame/ssl/teremok_space.key

# 2. Обновите сертификаты
make ssl-teremok

# 3. Перезапустите nginx
docker-compose -f docker-compose.prod.yml restart nginx
```

## 🚨 Решение проблем

### Если файлы не найдены:
```bash
# Проверьте, что файлы на месте
ls -la ssl/
# Должно показать:
# teremok_space.crt
# teremok_space.key

# Проверьте права доступа
chmod 644 ssl/teremok_space.crt
chmod 600 ssl/teremok_space.key
```

### Если сертификаты неправильные:
```bash
# Проверьте валидность сертификата
openssl x509 -in ssl/teremok_space.crt -text -noout

# Проверьте соответствие ключа
openssl x509 -noout -modulus -in ssl/teremok_space.crt | openssl md5
openssl rsa -noout -modulus -in ssl/teremok_space.key | openssl md5
# Хеши должны совпадать
```

### Если nginx не перезапускается:
```bash
# Проверьте конфигурацию nginx
docker-compose -f docker-compose.prod.yml exec nginx nginx -t

# Посмотрите логи nginx
docker-compose -f docker-compose.prod.yml logs nginx

# Принудительный перезапуск
docker-compose -f docker-compose.prod.yml stop nginx
docker-compose -f docker-compose.prod.yml start nginx
```

## ✅ Проверочный чеклист

- [ ] Файлы `teremok_space.crt` и `teremok_space.key` находятся в `/opt/memgame/ssl/`
- [ ] Выполнена команда `make ssl-teremok`
- [ ] Созданы файлы `cert.pem` и `key.pem`
- [ ] Права доступа установлены правильно
- [ ] Nginx перезапущен
- [ ] Сайт доступен по HTTPS

🎉 **Готово! Ваш SSL настроен для teremok.space** 