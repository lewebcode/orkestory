#!/bin/bash

# Простой скрипт для нагрузочного тестирования
# Использование: ./scripts/load-test-simple.sh [SERVICE_URL]

SERVICE_URL=${1:-"http://localhost:8080"}

echo "=== Простое нагрузочное тестирование ==="
echo "Service URL: $SERVICE_URL"
echo ""

# Проверка доступности
if ! curl -s "${SERVICE_URL}/api/health" > /dev/null 2>&1; then
    echo "❌ Сервис недоступен. Запустите port-forward:"
    echo "kubectl port-forward svc/sentiment-analyzer-service 8080:80"
    exit 1
fi

echo "✅ Сервис доступен"
echo ""
echo "Генерация CPU нагрузки (10 секунд)..."
echo "Для наблюдения за HPA в другом терминале выполните:"
echo "  kubectl get hpa sentiment-analyzer-hpa -w"
echo ""

# Генерация нагрузки
for i in {1..50}; do
    curl -s "${SERVICE_URL}/api/load?duration=1000&intensity=8000&type=cpu" > /dev/null &
done

echo "Ожидание завершения нагрузки..."
wait

echo ""
echo "✅ Нагрузка сгенерирована"
echo ""
echo "Проверьте статус HPA:"
echo "  kubectl get hpa sentiment-analyzer-hpa"
echo ""
echo "Проверьте поды:"
echo "  kubectl get pods -l app=sentiment-analyzer"
