# Переход на Delayed Job: Решение проблем с одновременным выполнением

## 🎯 **Почему Delayed Job лучше для вашего случая:**

### ❌ **Проблемы с Sidekiq:**
- **Polling каждые 5 секунд** - задачи накапливаются и выполняются пачками
- **Concurrency проблемы** - несколько worker'ов работают одновременно 
- **Redis lag** - задержки в сети между Docker контейнерами
- **Сложная отладка** - состояние задач хранится в Redis
- **Непредсказуемость** - зависит от внешних факторов (Redis, сеть)

### ✅ **Преимущества Delayed Job:**
- **Точное выполнение** - проверка каждую секунду вместо 5
- **Строгая последовательность** - один worker = одна задача в момент времени
- **База данных** - все задачи в PostgreSQL, легко отлаживать
- **Простота** - меньше движущихся частей, более предсказуемо
- **Надежность** - работает в том же процессе что и основное приложение

## 🔧 **Что изменилось:**

### 1. Конфигурация:
- ❌ `config/initializers/sidekiq.rb` → ✅ `config/initializers/delayed_job.rb`
- ❌ `config/sidekiq.yml` → ✅ Конфигурация в initializer'е
- ✅ `sleep_delay = 1` - проверка каждую секунду

### 2. Jobs:
- ❌ `queue_as :bot_sequential` → ✅ Убрано (не нужно)
- ✅ Логирование через callbacks
- ✅ Автоматический retry при ошибках

### 3. Docker:
- ❌ Redis контейнер → ✅ Удален 
- ❌ 4+ Sidekiq контейнера → ✅ 2 Delayed Job worker'а
- ✅ Меньше ресурсов, проще архитектура

### 4. Мониторинг:
```bash
# Статус очередей
docker-compose exec web bundle exec rake queue:status

# Запланированные задачи
docker-compose exec web bundle exec rake queue:delayed

# Очистить неудачные
docker-compose exec web bundle exec rake queue:clear_failed

# Перезапустить неудачные
docker-compose exec web bundle exec rake queue:retry_failed
```

## 🚀 **Применение изменений:**

### 1. Остановить текущую систему:
```bash
docker-compose down
```

### 2. Обновить зависимости:
```bash
bundle install
```

### 3. Пересобрать образы:
```bash
docker-compose build --no-cache
```

### 4. Запустить новую систему:
```bash
docker-compose up -d
```

### 5. Проверить статус:
```bash
docker-compose exec web bundle exec rake queue:status
```

## 📊 **Ожидаемые результаты:**

1. **Точное выполнение по времени** - задачи выполняются в момент наступления `run_at`
2. **Нет одновременного выполнения** - строго последовательно
3. **Простая отладка** - все задачи видны в таблице `delayed_jobs`
4. **Стабильность** - меньше зависимостей и точек отказа
5. **Производительность** - меньше overhead, прямая работа с БД

## 🔍 **Отладка проблем:**

### Проверить задачи в базе данных:
```sql
-- Все задачи
SELECT id, handler, run_at, attempts, locked_at FROM delayed_jobs;

-- Только запланированные
SELECT id, handler, run_at FROM delayed_jobs WHERE run_at > NOW();

-- Проблемные задачи
SELECT id, handler, attempts, last_error FROM delayed_jobs WHERE attempts > 0;
```

### Логи worker'ов:
```bash
# Основной worker
docker-compose logs -f delayed_job

# Bot worker
docker-compose logs -f delayed_job_bots
```

## 💡 **Дополнительные возможности:**

- **Приоритеты** - можно добавить через `priority` поле
- **Retry логика** - настраивается через `max_attempts`
- **Условия выполнения** - можно добавить проверки в jobs
- **Мониторинг** - веб-интерфейс через gem `delayed_job_web` 