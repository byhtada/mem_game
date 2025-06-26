# Быстрое развертывание обновленной версии

## 🚀 Автоматическое развертывание (рекомендуется)

```bash
# Перейти в директорию проекта
cd /opt/memgame

# Запустить автоматическое развертывание
./scripts/deploy.sh
```

## 🔧 Ручное развертывание

### 1. Подготовка
```bash
cd /opt/memgame
git pull origin master
```

### 2. Обновление с новой Docker структурой
```bash
# Остановка сервисов
docker-compose -f docker-compose.prod.yml down

# ВАЖНО: Пересборка с --no-cache для применения новой структуры Dockerfile
docker-compose -f docker-compose.prod.yml build --no-cache

# Запуск базы данных и выполнение миграций
docker-compose -f docker-compose.prod.yml up -d db
sleep 30  # Ждем готовности базы данных
docker-compose -f docker-compose.prod.yml run --rm web bundle exec rails db:migrate

# Запуск всех сервисов
docker-compose -f docker-compose.prod.yml up -d
```

### 3. Проверка
```bash
# Статус контейнеров
docker-compose -f docker-compose.prod.yml ps

# Логи приложения
docker-compose -f docker-compose.prod.yml logs -f web

# Проверка доступности
curl -f http://localhost:3000/health
```

## ⚡ Что изменилось в этой версии

- **Обновлена Docker структура** - теперь используется многоэтапная сборка
- **Улучшена безопасность** - приложение работает под non-root пользователем
- **Оптимизирован размер образов** - промежуточные файлы не попадают в финальный образ
- **Ускорен запуск** - предкомпилированный bootsnap
- **Удален Redis** - упрощена архитектура, используется только PostgreSQL
- **Sidekiq → Delayed Job** - более стабильная обработка фоновых задач

## 🔍 Мониторинг после обновления

```bash
# Размер образов (должен уменьшиться)
docker images | grep memgame

# Использование ресурсов
docker stats

# Логи в реальном времени
docker-compose -f docker-compose.prod.yml logs -f
```

## 🚨 Если что-то пошло не так

### Быстрый откат
```bash
# Откат изменений Docker
git checkout HEAD~1 -- Dockerfile.prod docker-compose.prod.yml

# Пересборка с предыдущей версией
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

### Восстановление из backup
```bash
# Если был создан backup
./scripts/backup.sh restore latest
```

## 📊 Health Check

После развертывания приложение должно отвечать на:
- `GET /health` - статус приложения
- `GET /` - главная страница

## 💡 Полезные команды

```bash
# Просмотр логов конкретного сервиса
docker-compose -f docker-compose.prod.yml logs web
docker-compose -f docker-compose.prod.yml logs delayed_job

# Выполнение команд в контейнере
docker-compose -f docker-compose.prod.yml exec web bash
docker-compose -f docker-compose.prod.yml exec web bundle exec rails console

# Проверка статуса задач Delayed Job
docker-compose -f docker-compose.prod.yml exec web bundle exec rails runner "puts Delayed::Job.count"

# Перезапуск конкретного сервиса
docker-compose -f docker-compose.prod.yml restart web
docker-compose -f docker-compose.prod.yml restart delayed_job
``` 