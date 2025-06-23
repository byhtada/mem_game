# MemGame API

Rails API приложение для игры MemCulture с интегрированным фронтендом.

## Фронтенд

Фронтенд приложения находится в папке `memgame_web` и автоматически интегрирован в Rails приложение.

### Запуск в development

1. Запустите Rails сервер:
```bash
rails server
```

2. Откройте браузер и перейдите на `http://localhost:3000`

Фронтенд будет доступен на корневом URL, а API endpoints доступны по своим маршрутам.

### Обновление фронтенда

Если вы внесли изменения в файлы фронтенда в папке `memgame_web`, используйте скрипт для пересборки:

```bash
./bin/update_frontend
```

Этот скрипт:
- Собирает фронтенд с webpack в production режиме
- Копирует собранные файлы в папку `public`
- Копирует необходимые ассеты и библиотеки

### Структура

- `memgame_web/` - исходный код фронтенда
- `public/` - собранный фронтенд, обслуживаемый Rails
- `bin/update_frontend` - скрипт для обновления фронтенда

### API Endpoints

Фронтенд использует относительные пути для обращения к API, все endpoints доступны на том же домене:

- `POST /save_user_data`
- `POST /get_user_data`
- `POST /find_game`
- `POST /create_game`
- `POST /join_to_game`
- И другие...

### Production

В production окружении фронтенд обслуживается непосредственно Rails сервером из папки `public`.

## Разработка

### Запуск фронтенда отдельно (для разработки UI)

Если нужно разрабатывать только фронтенд с hot reload:

```bash
cd memgame_web
npm run start
```

В этом режиме фронтенд будет доступен на `http://localhost:5500` и будет обращаться к API на `http://localhost:3000`.

### API Development

Для разработки API запустите Rails в development режиме:

```bash
rails server
```

API будет доступно на `http://localhost:3000`.
