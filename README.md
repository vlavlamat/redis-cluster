# 🚀 Redis Cluster on Docker

Инфраструктурный проект для развёртывания **Redis Cluster** в Docker-окружении с полной автоматизацией через **Makefile**.

Кластер состоит из **10 нод** (`redis-node1` … `redis-node10`) и может использоваться множеством приложений, подключающихся через общую внешнюю Docker-сеть.

---

## 🗂 Структура проекта

```bash
.
├── .gitignore                 # Игнорирует runtime-данные Redis
├── Makefile                   # 🆕 Автоматизация всех операций кластера
├── create-cluster.sh          # Скрипт для инициализации кластера
├── reset-cluster.sh           # Скрипт для сброса и пересоздания кластера
├── docker-compose.yml         # Конфигурация всех 10 нод
├── README.md                  # Этот файл
└── data/                      # (генерируется при запуске) тома данных нод
    ├── redis-node1/
    ├── redis-node2/
    └── ...
```

---

## ⚙️ Быстрый старт

### 🎯 Рекомендуемый способ (через Makefile):

1️⃣ Посмотри все доступные команды:

```bash
make help
```

2️⃣ Запусти кластер одной командой:

```bash
make up
```

3️⃣ **Инициализируй кластер**:

```bash
make create-cluster
```

### 📋 Альтернативный способ (через Docker Compose):

1️⃣ Создай внешнюю сеть:

```bash
make network-create
```

2️⃣ Запусти контейнеры:

```bash
docker compose up -d
```

3️⃣ Инициализируй кластер:

```bash
bash create-cluster.sh
```

---

## 🛠 Управление кластером

### 📊 Основные команды:

```bash
make status          # Статус всех контейнеров
make logs            # Просмотр логов
make check-cluster   # Проверка состояния кластера
make info            # Информация о кластере
make test            # Тестовое подключение
```

### ♻️ Сброс и пересоздание кластера:

```bash
make reset           # Полный сброс с подтверждением
make reset-force     # Принудительный сброс без подтверждения
```

Команда `reset` выполняет:
* Останавливает и удаляет все контейнеры с данными
* Очищает папку `./data`
* Перезапускает контейнеры
* Автоматически создает кластер заново

### 🔧 Диагностика и мониторинг:

```bash
make cli             # Подключение к Redis CLI
make monitor         # Мониторинг команд Redis
```

---

## 🌐 Сеть и подключение

Кластер работает во **внешней** выделенной сети:

```yaml
networks:
  redis-cluster-net:
    name: redis-cluster-net
    external: true  # 🆕 Внешняя сеть
```

### 🔗 Управление сетью:

```bash
make network-create  # Создать внешнюю сеть
make network-info    # Информация о сети
make network-remove  # Удалить сеть (с подтверждением)
```

### 📱 Подключение приложений:

Подключи приложение к сети и используй любую ноду:

```bash
docker run --network redis-cluster-net your-app
```

Строка подключения:
```ini
tcp://redis-node1:6379?prefix=my_project:
```

---

## 📈 Масштабирование

### ➕ Добавление новой ноды:

1. Обнови `docker-compose.yml`, добавив новую ноду
2. Используй Makefile:

   ```bash
   make add-node NODE=redis-node11:6379
   ```

### 🔄 Перераспределение слотов:

```bash
make reshard         # Интерактивное перераспределение
```

### ➖ Удаление ноды:

```bash
make info            # Получи NODE_ID
make remove-node NODE_ID=<node-id>
```

---

## 💾 Управление данными

### 📦 Создание бэкапов:

```bash
make backup          # Создать бэкап в ./backups/
```

Бэкап включает все данные Redis из папки `./data/` и сохраняется с временной меткой.

### 🔄 Восстановление из бэкапа:

```bash
make restore BACKUP=./backups/redis-backup-XXXXXXXX.tar.gz
```

### 🧹 Очистка данных:

```bash
make clean           # Очистить данные и volumes
make clean-all       # Полная очистка (включая образы)
```

---

## 🔧 Технические детали

### 📋 Конфигурация Redis:

- **Версия**: Redis 7.2-alpine
- **Архитектура**: 10 нод (5 мастеров + 5 реплик)
- **Память**: 2GB на ноду с политикой `allkeys-lru`
- **Персистентность**: AOF + RDB снапшоты
- **Сеть**: Внешняя Docker-сеть `redis-cluster-net`

### 🆕 Улучшения в текущей версии:

- ✅ **Исправлена конфигурация кластера**: каждая нода теперь правильно анонсирует свой IP
- ✅ **Makefile автоматизация**: 20+ команд для управления кластером
- ✅ **Внешняя сеть**: улучшенная изоляция и подключение приложений
- ✅ **Система бэкапов**: автоматическое создание и восстановление
- ✅ **Расширенная диагностика**: мониторинг и проверка состояния

### 📊 Порты и подключения:

```
redis-node1  -> localhost:7001
redis-node2  -> localhost:7002
redis-node3  -> localhost:7003
redis-node4  -> localhost:7004
redis-node5  -> localhost:7005
redis-node6  -> localhost:7006
redis-node7  -> localhost:7007
redis-node8  -> localhost:7008
redis-node9  -> localhost:7009
redis-node10 -> localhost:7010
```

---

## ❓ FAQ

**🚀 Как быстро начать работу?**
```bash
make up && make create-cluster
```

**🔄 Как полностью пересоздать кластер?**
```bash
make reset
```

**📱 Можно ли подключать несколько приложений?**
✅ Да! Используй уникальные `prefix` для каждого проекта, чтобы разделить ключи.

**🎯 К какой ноде подключаться?**
✅ К любой. Redis Cluster автоматически направляет запросы на нужную ноду.

**💾 Что хранится в папке `data/`?**
Runtime-данные (`dump.rdb`, `appendonly.aof`, `nodes.conf`) — **игнорируются в Git**.

**🌐 Как подключить внешнее приложение?**
```bash
docker run --network redis-cluster-net your-app
```

**📋 Как посмотреть все команды?**
```bash
make help
```

---

## 📚 Полезные ссылки

* [Redis Cluster — Официальная документация](https://redis.io/docs/management/scaling/)
* [redis-cli — Работа с кластером](https://redis.io/docs/manual/scaling/#using-the-redis-cli-tool)
* [Docker Compose — Внешние сети](https://docs.docker.com/compose/networking/#use-a-pre-existing-network)
