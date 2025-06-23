# Переменные
DOCKER_COMPOSE = docker-compose
DOCKER_COMPOSE_PROD = docker-compose -f docker-compose.prod.yml

.PHONY: help build up down logs shell migrate seed test clean restart status

# Помощь
help:
	@echo "Доступные команды:"
	@echo "  build          - Собрать Docker образы"
	@echo "  up             - Запустить приложение в development режиме"
	@echo "  down           - Остановить приложение"
	@echo "  logs           - Показать логи"
	@echo "  shell          - Открыть shell в Rails контейнере"
	@echo "  migrate        - Выполнить миграции"
	@echo "  seed           - Заполнить базу данных"
	@echo "  test           - Запустить тесты"
	@echo "  clean          - Очистить Docker данные"
	@echo "  restart        - Перезапустить приложение"
	@echo "  status         - Показать статус контейнеров"
	@echo "  frontend       - Пересобрать фронтенд"
	@echo ""
	@echo "Production команды:"
	@echo "  prod-build     - Собрать образы для продакшена"
	@echo "  prod-up        - Запустить в production режиме"
	@echo "  prod-down      - Остановить production"
	@echo "  prod-logs      - Логи production"
	@echo "  prod-shell     - Shell в production контейнере"
	@echo "  prod-backup    - Создать backup базы данных"
	@echo "  prod-restore   - Восстановить из backup"
	@echo "  ssl-cert       - Получить SSL сертификаты"
	@echo "  deploy         - Полное развертывание в продакшен"

# Development команды
build:
	$(DOCKER_COMPOSE) build

up:
	$(DOCKER_COMPOSE) up -d
	@echo "Приложение запущено на http://localhost:3000"

down:
	$(DOCKER_COMPOSE) down

logs:
	$(DOCKER_COMPOSE) logs -f

shell:
	$(DOCKER_COMPOSE) exec web bash

update:
	$(DOCKER_COMPOSE) exec web bundle exec bundle install

rails-console:
	$(DOCKER_COMPOSE) exec web bundle exec rails console

migrate:
	$(DOCKER_COMPOSE) exec web bundle exec rails db:migrate

seed:
	$(DOCKER_COMPOSE) exec web bundle exec rails db:seed

test:
	$(DOCKER_COMPOSE) exec web bundle exec rails test

restart:
	$(DOCKER_COMPOSE) restart

status:
	$(DOCKER_COMPOSE) ps

# Пересборка фронтенда
frontend:
	$(DOCKER_COMPOSE) exec web bash -c "cd memgame_web && npm run build && cp -r dist/* ../public/ && cp -r assets ../public/ && cp -r libs ../public/"

# Production команды
prod-build:
	$(DOCKER_COMPOSE_PROD) build --no-cache

prod-up:
	$(DOCKER_COMPOSE_PROD) up -d
	@echo "Production приложение запущено"
	@echo "Проверьте статус: make prod-status"

prod-down:
	$(DOCKER_COMPOSE_PROD) down

prod-logs:
	$(DOCKER_COMPOSE_PROD) logs -f

prod-shell:
	$(DOCKER_COMPOSE_PROD) exec web bash

prod-status:
	$(DOCKER_COMPOSE_PROD) ps
	@echo ""
	@echo "Health checks:"
	@docker ps --format "table {{.Names}}\t{{.Status}}"

# SSL и безопасность
ssl-cert:
	@echo "Получение SSL сертификатов..."
	@if [ -z "$(DOMAIN)" ]; then echo "Ошибка: переменная DOMAIN не установлена"; exit 1; fi
	@if [ -z "$(LETSENCRYPT_EMAIL)" ]; then echo "Ошибка: переменная LETSENCRYPT_EMAIL не установлена"; exit 1; fi
	mkdir -p certbot/www certbot/conf ssl
	$(DOCKER_COMPOSE_PROD) --profile certbot run --rm certbot \
		certonly --webroot \
		--webroot-path=/var/www/certbot \
		--email $(LETSENCRYPT_EMAIL) \
		--agree-tos \
		--no-eff-email \
		-d $(DOMAIN)
	sudo cp certbot/conf/live/$(DOMAIN)/fullchain.pem ssl/cert.pem
	sudo cp certbot/conf/live/$(DOMAIN)/privkey.pem ssl/key.pem
	@echo "SSL сертификаты установлены"

ssl-renew:
	$(DOCKER_COMPOSE_PROD) --profile certbot run --rm certbot renew --quiet
	sudo cp certbot/conf/live/$(DOMAIN)/fullchain.pem ssl/cert.pem
	sudo cp certbot/conf/live/$(DOMAIN)/privkey.pem ssl/key.pem
	$(DOCKER_COMPOSE_PROD) restart nginx
	@echo "SSL сертификаты обновлены"

# Backup и восстановление
prod-backup:
	@echo "Создание backup базы данных..."
	mkdir -p backups
	$(DOCKER_COMPOSE_PROD) exec -T db pg_dump -U memgame memgame_production > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Backup создан в папке backups/"

prod-restore:
	@if [ -z "$(BACKUP_FILE)" ]; then echo "Ошибка: укажите файл backup: make prod-restore BACKUP_FILE=backups/backup_file.sql"; exit 1; fi
	@echo "Восстановление из $(BACKUP_FILE)..."
	$(DOCKER_COMPOSE_PROD) stop web sidekiq
	cat $(BACKUP_FILE) | $(DOCKER_COMPOSE_PROD) exec -T db psql -U memgame -d memgame_production
	$(DOCKER_COMPOSE_PROD) start web sidekiq
	@echo "Восстановление завершено"

# Полное развертывание
deploy: prod-build
	@echo "🚀 Начинаем развертывание в продакшен..."
	@if [ ! -f .env ]; then echo "❌ Файл .env не найден. Скопируйте env.production.example в .env"; exit 1; fi
	mkdir -p ssl backups certbot/www certbot/conf logs
	@echo "✅ Директории созданы"
	$(DOCKER_COMPOSE_PROD) up -d
	@echo "✅ Сервисы запущены"
	@echo "⏳ Ожидание готовности сервисов..."
	sleep 30
	@echo "🔍 Проверка статуса..."
	make prod-status
	@echo ""
	@echo "🎉 Развертывание завершено!"
	@echo "🌐 Приложение доступно по адресу: https://$(DOMAIN)"

# Очистка
clean:
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans
	docker system prune -f

clean-prod:
	$(DOCKER_COMPOSE_PROD) down -v --rmi all --remove-orphans
	docker system prune -f

clean-volumes:
	$(DOCKER_COMPOSE) down -v
	$(DOCKER_COMPOSE_PROD) down -v

# База данных
db-reset:
	$(DOCKER_COMPOSE) exec web bundle exec rails db:drop db:create db:migrate db:seed

prod-migrate:
	$(DOCKER_COMPOSE_PROD) exec web bundle exec rails db:migrate

prod-console:
	$(DOCKER_COMPOSE_PROD) exec web bundle exec rails console

# Sidekiq
sidekiq-restart:
	$(DOCKER_COMPOSE) restart sidekiq

sidekiq-logs:
	$(DOCKER_COMPOSE) logs -f sidekiq

prod-sidekiq-restart:
	$(DOCKER_COMPOSE_PROD) restart sidekiq

prod-sidekiq-logs:
	$(DOCKER_COMPOSE_PROD) logs -f sidekiq

# Мониторинг
monitor:
	@echo "📊 Мониторинг системы:"
	@echo ""
	@echo "🐳 Docker статистика:"
	@docker stats --no-stream
	@echo ""
	@echo "💾 Использование диска:"
	@df -h
	@echo ""
	@echo "🔧 Статус сервисов:"
	@make prod-status

# Установка и первый запуск
setup: build
	$(DOCKER_COMPOSE) up -d db redis
	@echo "Ожидание запуска базы данных..."
	sleep 10
	$(DOCKER_COMPOSE) run --rm web bundle exec rails db:create db:migrate db:seed
	@echo "Настройка завершена. Используйте 'make up' для запуска"

# Проверка безопасности
security-check:
	@echo "🔒 Проверка безопасности:"
	@echo ""
	@echo "SSL сертификаты:"
	@if [ -f ssl/cert.pem ]; then openssl x509 -in ssl/cert.pem -noout -dates; else echo "SSL сертификаты не найдены"; fi
	@echo ""
	@echo "Права доступа к файлам:"
	@ls -la .env ssl/ 2>/dev/null || echo "Некоторые файлы не найдены"
	@echo ""
	@echo "Открытые порты:"
	@netstat -tulpn | grep -E ':(80|443|3000|5432|6379)' || echo "Порты не открыты" 