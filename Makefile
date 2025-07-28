# Redis Cluster Makefile
# Управление Redis кластером в Docker окружении

# Переменные
COMPOSE_FILE = docker-compose.yml
NETWORK_NAME = redis-cluster-net
DATA_DIR = ./data
REDIS_IMAGE = redis:7.2-alpine
CLUSTER_NODES = redis-node1:6379 redis-node2:6379 redis-node3:6379 redis-node4:6379 redis-node5:6379 redis-node6:6379 redis-node7:6379 redis-node8:6379 redis-node9:6379 redis-node10:6379

# Цели по умолчанию
.PHONY: help up down restart status logs clean reset create-cluster check-cluster info reshard add-node remove-node backup restore test

# Показать справку
help:
	@echo "Redis Cluster - Доступные команды:"
	@echo ""
	@echo "Управление контейнерами:"
	@echo "  make up              - Запустить все Redis ноды"
	@echo "  make down            - Остановить все контейнеры"
	@echo "  make restart         - Перезапустить все контейнеры"
	@echo "  make status          - Показать статус контейнеров"
	@echo "  make logs            - Показать логи всех контейнеров"
	@echo ""
	@echo "Управление кластером:"
	@echo "  make create-cluster  - Создать Redis кластер"
	@echo "  make reset           - Полный сброс кластера (с подтверждением)"
	@echo "  make reset-force     - Принудительный сброс без подтверждения"
	@echo "  make check-cluster   - Проверить состояние кластера"
	@echo "  make info            - Показать информацию о кластере"
	@echo "  make reshard         - Перераспределить слоты кластера"
	@echo ""
	@echo "Диагностика:"
	@echo "  make test            - Тестовое подключение к кластеру"
	@echo "  make cli             - Подключиться к Redis CLI"
	@echo "  make monitor         - Мониторинг команд Redis"
	@echo ""
	@echo "Управление данными:"
	@echo "  make backup          - Создать бэкап данных"
	@echo "  make restore         - Восстановить данные из бэкапа"
	@echo "  make clean           - Очистить данные и volumes"
	@echo ""
	@echo "Внешняя сеть:"
	@echo "  make network-create  - Создать внешнюю Docker сеть"
	@echo "  make network-remove  - Удалить внешнюю сеть (с подтверждением)"
	@echo "  make network-info    - Показать информацию о сети"
	@echo ""
	@echo "💡 Подключение приложений к сети:"
	@echo "  docker run --network redis-cluster-net your-app"

# Запуск контейнеров
up:
	@echo "Запуск Redis контейнеров..."
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || make network-create
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "Контейнеры запущены!"
	@echo "Выполните 'make create-cluster' для инициализации кластера"

# Остановка контейнеров
down:
	@echo "Остановка Redis контейнеров..."
	@docker compose -f $(COMPOSE_FILE) down
	@echo "Контейнеры остановлены!"

# Перезапуск
restart: down up

# Статус контейнеров
status:
	@echo "Статус Redis контейнеров:"
	@docker compose -f $(COMPOSE_FILE) ps

# Логи
logs:
	@echo "Логи Redis контейнеров:"
	@docker compose -f $(COMPOSE_FILE) logs -f --tail=100

# Создание кластера (из скрипта create-cluster.sh)
create-cluster:
	@echo "Создание Redis кластера..."
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || make network-create
	@yes yes | docker run -i --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli --cluster create \
		$(CLUSTER_NODES) \
		--cluster-replicas 1
	@echo "Кластер создан!"

# Проверка кластера
check-cluster:
	@echo "Проверка состояния кластера..."
	@docker run -it --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli --cluster check redis-node1:6379

# Информация о кластере
info:
	@echo "Информация о кластере:"
	@docker run -it --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli --cluster info redis-node1:6379

# Перераспределение слотов
reshard:
	@echo "♻Перераспределение слотов кластера..."
	@docker run -it --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli --cluster reshard redis-node1:6379

# Сброс кластера (из скрипта reset-cluster.sh)
reset:
	@echo "WARNING: Это удалит ВСЕ данные Redis кластера!"
	@read -p "Продолжить? (yes/no): " confirm && \
	if [ "$$confirm" = "yes" ]; then \
		make reset-force; \
	else \
		echo "Отменено"; \
		exit 1; \
	fi

# Принудительный сброс без подтверждения
reset-force:
	@echo "Остановка Redis контейнеров..."
	@docker compose -f $(COMPOSE_FILE) down -v
	@echo "Удаление данных Redis..."
	@rm -rf $(DATA_DIR)/redis-node*
	@echo "Запуск контейнеров..."
	@make up
	@echo "Ожидание инициализации нод (5 секунд)..."
	@sleep 5
	@echo "Создание кластера..."
	@make create-cluster
	@echo "Сброс кластера завершен!"

# Тестовое подключение
test:
	@echo "Тестирование подключения к кластеру..."
	@docker run -it --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli -c -h redis-node1 -p 6379 ping
	@echo "Тест успешен!"

# Подключение к CLI
cli:
	@echo "Подключение к Redis CLI..."
	@docker run -it --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli -c -h redis-node1 -p 6379

# Мониторинг команд
monitor:
	@echo "Мониторинг Redis команд..."
	@docker run -it --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli -h redis-node1 -p 6379 monitor

# Добавление новой ноды
add-node:
	@if [ -z "$(NODE)" ]; then \
		echo "Укажите NODE=redis-nodeX:6379"; \
		exit 1; \
	fi
	@echo "➕ Добавление ноды $(NODE) в кластер..."
	@docker run -it --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli --cluster add-node $(NODE) redis-node1:6379

# Удаление ноды
remove-node:
	@if [ -z "$(NODE_ID)" ]; then \
		echo "Укажите NODE_ID=<node-id>"; \
		echo "Получите NODE_ID командой: make info"; \
		exit 1; \
	fi
	@echo "Удаление ноды $(NODE_ID) из кластера..."
	@docker run -it --rm --net $(NETWORK_NAME) $(REDIS_IMAGE) \
		redis-cli --cluster del-node redis-node1:6379 $(NODE_ID)

# Создание бэкапа
backup:
	@echo "Создание бэкапа Redis данных..."
	@mkdir -p ./backups
	@tar -czf ./backups/redis-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz $(DATA_DIR)
	@echo "Бэкап создан в папке ./backups/"

# Восстановление из бэкапа
restore:
	@if [ -z "$(BACKUP)" ]; then \
		echo "Укажите файл бэкапа: make restore BACKUP=./backups/redis-backup-XXXXXXXX.tar.gz"; \
		echo "Доступные бэкапы:"; \
		ls -la ./backups/ 2>/dev/null || echo "Нет доступных бэкапов"; \
		exit 1; \
	fi
	@echo "Восстановление из бэкапа $(BACKUP)..."
	@make down
	@rm -rf $(DATA_DIR)
	@tar -xzf $(BACKUP)
	@make up
	@echo "Восстановление завершено!"

# Создание Docker сети
network-create:
	@echo "Создание внешней Docker сети $(NETWORK_NAME)..."
	@docker network create --driver bridge $(NETWORK_NAME) 2>/dev/null || true
	@echo "Внешняя сеть $(NETWORK_NAME) создана!"
	@echo "Теперь приложения могут подключаться к этой сети"

# Удаление Docker сети
network-remove:
	@echo "ВНИМАНИЕ: Удаление сети $(NETWORK_NAME) отключит ВСЕ приложения!"
	@read -p "Продолжить? (yes/no): " confirm && \
	if [ "$$confirm" = "yes" ]; then \
		docker network rm $(NETWORK_NAME) 2>/dev/null || true; \
		echo "Сеть удалена!"; \
	else \
		echo "Отменено"; \
	fi

# Показать информацию о сети
network-info:
	@echo "Информация о сети $(NETWORK_NAME):"
	@docker network inspect $(NETWORK_NAME) 2>/dev/null || echo "Сеть не существует"
	@echo ""
	@echo "Подключенные контейнеры:"
	@docker network inspect $(NETWORK_NAME) -f '{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' 2>/dev/null || echo "Нет подключенных контейнеров"

# Очистка данных и volumes
clean:
	@echo "Очистка данных и Docker volumes..."
	@make down
	@docker compose -f $(COMPOSE_FILE) down -v --remove-orphans
	@rm -rf $(DATA_DIR)
	@docker system prune -f --volumes
	@echo "Очистка завершена!"

# Полная очистка (включая образы)
clean-all: clean
	@echo "Полная очистка (включая Docker образы)..."
	@docker image rm $(REDIS_IMAGE) 2>/dev/null || true
	@docker system prune -af --volumes
	@make network-remove
	@echo "Полная очистка завершена!"

# Показать конфигурацию
config:
	@echo "Текущая конфигурация:"
	@echo "Docker Compose файл: $(COMPOSE_FILE)"
	@echo "Сеть: $(NETWORK_NAME)"
	@echo "Папка данных: $(DATA_DIR)"
	@echo "Redis образ: $(REDIS_IMAGE)"
	@echo "Ноды кластера: $(CLUSTER_NODES)"

# Установка по умолчанию - показать справку
.DEFAULT_GOAL := help