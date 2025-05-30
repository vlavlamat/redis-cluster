Вот улучшенный и более аккуратный README для твоего проекта, с учётом всей структуры и скриптов:

---

# 🚀 Redis Cluster on Docker

Инфраструктурный проект для развёртывания **Redis Cluster** в Docker-окружении.

Кластер состоит из **10 нод** (`redis-node1` … `redis-node10`) и может использоваться множеством приложений, подключающихся через общую внешнюю Docker-сеть.

---

## 🗂 Структура проекта

```bash
.
├── .gitignore                 # Игнорирует runtime-данные Redis
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

1️⃣ Запусти все контейнеры:

```bash
docker compose up -d
```

2️⃣ **Инициализируй кластер** (нужно выполнить только один раз после первого запуска):

```bash
bash create-cluster.sh
```

---

## ♻️ Сброс и пересоздание кластера

Если нужно полностью пересоздать кластер (с удалением всех данных):

```bash
bash reset-cluster.sh
```

Этот скрипт:

* Останавливает и удаляет все контейнеры с данными
* Очищает папку `./data`
* Перезапускает контейнеры
* Запускает скрипт `create-cluster.sh` заново

---

## 🌐 Сеть и подключение

Кластер работает в выделенной сети:

```yaml
networks:
  redis-cluster-net:
    name: redis-cluster-net
```

Чтобы подключить внешние приложения:

* Подключи их к сети `redis-cluster-net`
* Используй любой из нод:

```ini
tcp://redis-node1:6379?prefix=my_project:
```

---

## 📈 Масштабирование

Добавление новых нод:

1. Обнови `docker-compose.yml`, добавив `redis-node11`, `redis-node12` и т. д.
2. Выполни:

   ```bash
   redis-cli --cluster add-node redis-node11:6379 redis-node1:6379
   ```
3. При необходимости перераспредели слоты:

   ```bash
   redis-cli --cluster reshard redis-node1:6379
   ```

---

## ❓ FAQ

**Можно ли подключать несколько проектов?**
✅ Да! Используй уникальные `prefix` для каждого проекта, чтобы разделить ключи.

**К какой ноде подключаться?**
✅ К любой. Redis Cluster сам направляет запросы на нужную ноду по слотам.

**Что хранится в папке `data/`?**
Все runtime-данные (`dump.rdb`, `appendonly.aof`, `nodes.conf`) — **эти файлы игнорируются в Git**.

---

## 📚 Полезные ссылки

* [Redis Cluster — Официальная документация](https://redis.io/docs/management/scaling/)
* [redis-cli — Работа с кластером](https://redis.io/docs/manual/scaling/#using-the-redis-cli-tool)
