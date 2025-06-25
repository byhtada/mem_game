# 🔌 WebSocket реализация для сценария ожидания игры

## 📋 Обзор изменений

Переделан метод `get_update_game_ready` с polling на веб-сокеты с использованием **Action Cable**.

## 🔧 Реализованные компоненты

### Бэкенд (Rails)

1. **GameChannel** (`app/channels/game_channel.rb`)
   - Обрабатывает подписки на обновления игры в состоянии регистрации
   - Проверяет права доступа пользователя
   - Автоматически отправляет текущее состояние при подписке

2. **RoundChannel** (`app/channels/round_channel.rb`)
   - Обрабатывает подписки на обновления раунда в состоянии игры
   - Проверяет права доступа пользователя к игре
   - Автоматически отправляет текущее состояние раунда при подписке

3. **VoteChannel** (`app/channels/vote_channel.rb`)
   - Обрабатывает подписки на обновления голосования
   - Проверяет права доступа пользователя к игре
   - Автоматически отправляет текущее состояние голосования при подписке

4. **Connection** (`app/channels/application_cable/connection.rb`)
   - Аутентификация через `user_id` параметр
   - Идентификация пользователей для Action Cable

5. **Game Model** (`app/models/game.rb`)
   - Метод `broadcast_game_update()` для отправки обновлений
   - Автоматическое broadcasting при изменениях состояния игры
   - Broadcasting при добавлении игроков

6. **Round Model** (`app/models/round.rb`)
   - Метод `broadcast_round_update()` для отправки обновлений раунда
   - Метод `broadcast_vote_update()` для отправки обновлений голосования
   - Автоматическое broadcasting при изменениях состояния раунда
   - Broadcasting при добавлении мемов и голосов игроками

7. **Маршруты** (`config/routes.rb`)
   - Добавлен endpoint `/cable` для WebSocket соединений

### Фронтенд (JavaScript)

1. **Action Cable Consumer** (`memgame_web/js/consumer.js`)
   - Кастомная реализация Action Cable клиента
   - Автоматическое переподключение при разрыве связи
   - Управление подписками

2. **Обновленная логика игры** (`memgame_web/js/app.js`)
   - Функция `subscribeToGameUpdates()` для WebSocket подписки на игру
   - Функция `subscribeToRoundUpdates()` для WebSocket подписки на раунд
   - Функция `subscribeToVoteUpdates()` для WebSocket подписки на голосование
   - Fallback на polling при проблемах с WebSocket
   - Общие обработчики `handleGameUpdate()`, `handleRoundUpdate()` и `handleVoteUpdate()` для обоих методов
   - Автоматическое отключение при уходе со страницы

## 🚀 Как это работает

### Фаза ожидания игры:
1. При входе в игру вызывается `timeoutGameWait()`
2. Если веб-сокеты включены, создается подписка на `GameChannel`
3. При добавлении игрока в модели Game вызывается `broadcast_game_update`
4. Все подписанные клиенты получают real-time обновления
5. При достижении `ready_to_start: true` подписка отключается

### Фаза раунда:
1. При начале раунда вызывается `timeoutRoundWait()`
2. Если веб-сокеты включены, создается подписка на `RoundChannel`
3. При отправке мема в модели Round вызывается `broadcast_round_update`
4. Все подписанные клиенты получают real-time обновления о мемах
5. При достижении `ready_to_open: true` подписка отключается

### Фаза голосования:
1. При начале голосования вызывается `timeoutVotesWait()`
2. Если веб-сокеты включены, создается подписка на `VoteChannel`
3. При голосовании в модели Round вызывается `broadcast_vote_update`
4. Все подписанные клиенты получают real-time обновления о голосах
5. При завершении голосования подписка отключается

### Общие принципы:
6. При проблемах с WebSocket автоматически переключается на polling

## 🔀 Fallback механизм

- **WebSocket активен**: мгновенные обновления, низкая нагрузка на сервер
- **WebSocket недоступен**: автоматическое переключение на HTTP polling
- **Переподключение**: автоматические попытки восстановления соединения

## 🎯 Преимущества

- ⚡ **Мгновенные обновления** вместо задержки до 1 секунды
- 📉 **Снижение нагрузки** на сервер (нет постоянных HTTP запросов)
- 🔄 **Надежность** с fallback на polling
- 🧩 **Обратная совместимость** со старым кодом

## 🧪 Тестирование

### Автоматическое тестирование
1. Запустите сервер: `rails server`
2. Откройте `/test_websockets.html` в браузере
3. Укажите User ID и Game ID
4. Нажмите "Подключиться" и наблюдайте за логами

### Ручное тестирование GameChannel
1. Откройте DevTools -> Network -> WS
2. Создайте игру через основной интерфейс
3. Добавьте игроков в разных вкладках
4. Убедитесь в real-time обновлениях

### Тестирование RoundChannel
1. **Создание тестовых данных**: `ruby test_round_websocket.rb`
2. **Интерактивное тестирование**: откройте `/test_round_websockets.html`

### Тестирование VoteChannel
1. **Создание тестовых данных**: `ruby test_vote_websocket.rb`
2. **Интерактивное тестирование**: откройте `/test_vote_websockets.html`

### Тестирование GameChannel
1. **Автоматическое тестирование**: откройте `/test_websockets.html`

## 🔧 Настройки

- **Включить/отключить WebSocket**: `isWebSocketsEnabled = true/false` в `app.js`
- **URL WebSocket**: по умолчанию `/cable`
- **Переподключение**: автоматически через 3 секунды при разрыве

## 📝 Логи

В консоли браузера будут отображаться:
- `🔗 Connected to Action Cable`
- `🎮 Connected to game channel`
- `🎮 WebSocket game update received:`
- `🎮 Connected to round channel`
- `🎮 WebSocket round update received:`
- `🎮 Connected to vote channel`
- `🎮 WebSocket vote update received:`
- `🔄 Falling back to polling due to WebSocket disconnect`

## 🚧 Следующие шаги

### ✅ Уже реализовано:
- `get_update_game_ready` (ожидание игры) → **GameChannel**
- `get_round_update` (ожидание раунда) → **RoundChannel**
- `get_vote_update` (голосование) → **VoteChannel**

### 🔄 Можно дополнительно переделать:
- `get_restart_update` (рестарт игры) → **RestartChannel**

Для этого нужно создать отдельный канал аналогично уже существующим.

## 🔧 Исправленные проблемы

### Redis адаптер
- **Проблема**: `Gem::LoadError` - отсутствовал Redis gem
- **Решение**: Добавлен `gem "redis", ">= 4.0.1"` в Gemfile
- **Development**: Настроен `async` адаптер для работы без Redis в development

### Дублирование данных
- **Проблема**: Дублирование GameUser записей в broadcasting
- **Решение**: Добавлен `.reload.order(:created_at)` в `users_for_broadcast`

### Action Cable конфигурация  
- **Development**: `adapter: async` (не требует Redis)
- **Production**: `adapter: redis` (использует Redis для масштабирования)

## 📁 Тестовые файлы

- `public/test_websockets.html` - интерактивный тестер GameChannel соединений
- `public/test_round_websockets.html` - интерактивный тестер RoundChannel соединений  
- `public/test_vote_websockets.html` - интерактивный тестер VoteChannel соединений
- `test_websocket.rb` - создание тестовых данных для GameChannel
- `test_round_websocket.rb` - создание тестовых данных для RoundChannel
- `test_vote_websocket.rb` - создание тестовых данных для VoteChannel
- Позволяет проверить подключение, подписку и получение данных в real-time

## 📋 Резюме реализации

### ✅ Что реализовано:
1. **GameChannel** - WebSocket канал для замены `get_update_game_ready`
2. **RoundChannel** - WebSocket канал для замены `get_round_update`
3. **VoteChannel** - WebSocket канал для замены `get_vote_update`
4. **Автоматическое broadcasting** при отправке мемов, голосовании и изменении состояний
5. **Клиентский код** с поддержкой WebSocket и fallback на polling
6. **Тестовые инструменты** для проверки функциональности
7. **Полная документация** с примерами использования

### 🎯 Результат:
- **Мгновенные обновления** вместо задержки до 1 секунды при отправке мемов и голосовании
- **Снижение нагрузки** на сервер (нет постоянных HTTP запросов)
- **Надежность** с автоматическим fallback на polling
- **Обратная совместимость** со старым кодом

### 🚀 Следующий этап:
Аналогично можно реализовать WebSocket канал для:
- `get_restart_update` (RestartChannel) 