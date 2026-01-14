#!/bin/bash

# Скрипт для нагрузочного тестирования приложения
# Использование: ./scripts/load-test.sh [SERVICE_URL] [DURATION] [CONCURRENT_USERS]

set -e

SERVICE_URL=${1:-"http://localhost:8080"}
DURATION=${2:-30}
CONCURRENT_USERS=${3:-10}

echo "=== Нагрузочное тестирование Sentiment Analyzer ==="
echo "Service URL: $SERVICE_URL"
echo "Duration: ${DURATION}s"
echo "Concurrent users: $CONCURRENT_USERS"
echo ""

# Функция для генерации CPU нагрузки
generate_cpu_load() {
    local url=$1
    local duration=$2
    local iterations=$3
    
    for i in $(seq 1 $iterations); do
        curl -s "${url}/api/load?duration=${duration}&intensity=5000&type=cpu" > /dev/null 2>&1 &
    done
    wait
}

# Функция для генерации обычных запросов
generate_normal_load() {
    local url=$1
    local iterations=$2
    
    for i in $(seq 1 $iterations); do
        curl -s "${url}/api/sentiment?text=This%20is%20a%20test%20request%20number%20${i}" > /dev/null 2>&1 &
    done
    wait
}

# Проверка доступности сервиса
echo "Проверка доступности сервиса..."
if ! curl -s "${SERVICE_URL}/api/health" > /dev/null 2>&1; then
    echo "❌ Сервис недоступен по адресу $SERVICE_URL"
    echo "Запустите: kubectl port-forward svc/sentiment-analyzer-service 8080:80"
    exit 1
fi
echo "✅ Сервис доступен"
echo ""

# Тест 1: Легкая нагрузка
echo "Тест 1: Легкая нагрузка (${CONCURRENT_USERS} пользователей, 5 секунд)"
START_TIME=$(date +%s)
for i in $(seq 1 $CONCURRENT_USERS); do
    generate_normal_load "$SERVICE_URL" 10 &
done
wait
END_TIME=$(date +%s)
echo "✅ Легкая нагрузка завершена за $((END_TIME - START_TIME)) секунд"
echo ""

sleep 2

# Тест 2: Средняя нагрузка
echo "Тест 2: Средняя нагрузка (CPU нагрузка, ${CONCURRENT_USERS} пользователей)"
START_TIME=$(date +%s)
for i in $(seq 1 $CONCURRENT_USERS); do
    generate_cpu_load "$SERVICE_URL" 500 5 &
done
wait
END_TIME=$(date +%s)
echo "✅ Средняя нагрузка завершена за $((END_TIME - START_TIME)) секунд"
echo ""

sleep 2

# Тест 3: Высокая нагрузка (для тестирования HPA)
echo "Тест 3: Высокая нагрузка (CPU нагрузка, $((CONCURRENT_USERS * 3)) пользователей, ${DURATION} секунд)"
START_TIME=$(date +%s)
END_TEST_TIME=$((START_TIME + DURATION))

while [ $(date +%s) -lt $END_TEST_TIME ]; do
    for i in $(seq 1 $((CONCURRENT_USERS * 3))); do
        curl -s "${SERVICE_URL}/api/load?duration=1000&intensity=10000&type=cpu" > /dev/null 2>&1 &
    done
    sleep 1
done
wait
END_TIME=$(date +%s)
echo "✅ Высокая нагрузка завершена за $((END_TIME - START_TIME)) секунд"
echo ""

echo "=== Нагрузочное тестирование завершено ==="
echo ""
echo "Для проверки HPA выполните:"
echo "  kubectl get hpa sentiment-analyzer-hpa -w"
echo ""
echo "Для проверки подов:"
echo "  kubectl get pods -l app=sentiment-analyzer -w"
