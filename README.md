# Sentiment Analyzer - AI Application for Kubernetes

Итоговый проект по разработке и развертыванию ИИ-приложения в Kubernetes.

## Описание проекта

Приложение для анализа тональности текста на Java Spring Boot, развернутое в Kubernetes (Minikube) с мониторингом через Prometheus и Grafana.

## Архитектура

- **Java Spring Boot** приложение с REST API
- **Docker** контейнеризация
- **Kubernetes** оркестрация (Minikube)
- **Prometheus** для сбора метрик
- **Grafana** для визуализации
- **HPA** для автоматического масштабирования
- **Ingress** для маршрутизации трафика

## Требования

- Java 17+
- Maven 3.6+
- Docker
- Minikube
- kubectl
- Helm 3+

## Установка и развертывание

### 1. Установка Minikube

```bash
# Для macOS
brew install minikube

# Для Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Для Windows
# Скачайте установщик с https://minikube.sigs.k8s.io/docs/start/
```

### 2. Настройка Minikube

```bash
# Запустите скрипт настройки
chmod +x scripts/setup-minikube.sh
./scripts/setup-minikube.sh
```

Или вручную:

```bash
minikube start --cpus=4 --memory=8192mb --nodes=2
minikube addons enable ingress
minikube addons enable metrics-server
```

### 3. Сборка приложения

```bash
# Сборка Java приложения
chmod +x scripts/build.sh
./scripts/build.sh
```

### 4. Сборка Docker образа

```bash
# Сборка и загрузка образа в Minikube
chmod +x scripts/docker-build.sh
./scripts/docker-build.sh
```

Или вручную:

```bash
docker build -t sentiment-analyzer:latest .
minikube image load sentiment-analyzer:latest
```

### 5. Развертывание в Kubernetes

```bash
# Развертывание всех компонентов
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Или вручную:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
```

### 6. Настройка мониторинга

```bash
# Установка Prometheus и Grafana
chmod +x scripts/setup-monitoring.sh
./scripts/setup-monitoring.sh
```

Или вручную:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

kubectl apply -f k8s/service-monitor.yaml
```

## Использование API

### Важно: Все эндпоинты находятся по пути `/api/...`

⚠️ **Примечание:** Корневой путь `/` не имеет маппинга. Всегда используйте путь `/api/...` для доступа к API.

### Получение статуса сервиса

**Вариант 1: Через port-forward (рекомендуется)**

```bash
# В одном терминале
kubectl port-forward svc/sentiment-analyzer-service 8080:80

# В другом терминале (или после Ctrl+Z и bg)
curl http://localhost:8080/api/health
```

**Вариант 2: Через minikube service**

```bash
# Получить URL
SERVICE_URL=$(minikube service sentiment-analyzer-service --url)

# Использовать URL
curl $SERVICE_URL/api/health

# Или напрямую
curl $(minikube service sentiment-analyzer-service --url)/api/health
```

**Вариант 3: Через minikube tunnel (для LoadBalancer)**

```bash
# В одном терминале (отдельный процесс)
minikube tunnel

# В другом терминале
kubectl get service sentiment-analyzer-service
# Использовать EXTERNAL-IP из вывода
curl http://<EXTERNAL-IP>/api/health
```

### Анализ тональности текста

```bash
# Через port-forward
curl "http://localhost:8080/api/sentiment?text=I%20love%20this%20application"

# Через minikube service
curl "$(minikube service sentiment-analyzer-service --url)/api/sentiment?text=I%20love%20this%20application"
```

Ответ:
```json
{
  "sentiment": "positive",
  "text": "I love this application",
  "confidence": 0.95
}
```

### Тестирование нагрузки (новый эндпоинт)

```bash
# Генерация CPU нагрузки
curl "http://localhost:8080/api/load?duration=1000&intensity=5000&type=cpu"

# Через minikube service
curl "$(minikube service sentiment-analyzer-service --url)/api/load?duration=1000&intensity=5000&type=cpu"
```

### Метрики Prometheus

```bash
# Через port-forward
kubectl port-forward svc/sentiment-analyzer-service 8080:80
curl http://localhost:8080/actuator/prometheus

# Через minikube service
curl "$(minikube service sentiment-analyzer-service --url)/actuator/prometheus"
```

## Доступ к Grafana

```bash
# Получить пароль
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode

# Проброс порта
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Откройте http://localhost:3000 в браузере:
- Username: `admin`
- Password: (из команды выше)

## Проверка развертывания

```bash
# Проверить поды
kubectl get pods -l app=sentiment-analyzer

# Проверить сервисы
kubectl get services

# Проверить Ingress
kubectl get ingress

# Проверить HPA
kubectl get hpa

# Проверить логи
kubectl logs -l app=sentiment-analyzer --tail=50
```

## Тестирование масштабирования

**Вариант 1: Использование скрипта нагрузочного тестирования**

```bash
# Установить port-forward в отдельном терминале
kubectl port-forward svc/sentiment-analyzer-service 8080:80

# Запустить скрипт нагрузочного тестирования
./scripts/load-test-simple.sh http://localhost:8080

# В другом терминале наблюдать за масштабированием
watch kubectl get hpa sentiment-analyzer-hpa
watch kubectl get pods -l app=sentiment-analyzer
```

**Вариант 2: Использование kubectl run**

```bash
# Создать нагрузку для тестирования HPA
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- \
  /bin/sh -c "while sleep 0.01; do wget -q -O- http://sentiment-analyzer-service/api/load?duration=1000&intensity=10000&type=cpu; done"

# В другом терминале наблюдать за масштабированием
watch kubectl get hpa sentiment-analyzer-hpa
```

**Вариант 3: Использование эндпоинта /api/load напрямую**

```bash
# Генерация нагрузки через API
for i in {1..100}; do
  curl "$(minikube service sentiment-analyzer-service --url)/api/load?duration=2000&intensity=8000&type=cpu" > /dev/null 2>&1 &
done
wait

# Наблюдать за масштабированием
kubectl get hpa sentiment-analyzer-hpa -w
```

## Структура проекта

```
orkestory/
├── src/
│   └── main/
│       ├── java/com/orkestory/
│       │   ├── SentimentAnalyzerApplication.java
│       │   ├── controller/
│       │   │   └── SentimentController.java
│       │   └── service/
│       │       └── SentimentService.java
│       └── resources/
│           └── application.yml
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   └── service-monitor.yaml
├── scripts/
│   ├── setup-minikube.sh
│   ├── build.sh
│   ├── docker-build.sh
│   ├── deploy.sh
│   └── setup-monitoring.sh
├── Dockerfile
├── pom.xml
└── README.md
```

## Размер Docker образа

Образ должен быть менее 150MB благодаря использованию:
- Alpine Linux базового образа
- Multi-stage build
- Оптимизированных зависимостей

Проверить размер:
```bash
docker images sentiment-analyzer:latest
```

## Мониторинг метрик

Приложение экспортирует метрики через Spring Boot Actuator:
- `/actuator/health` - статус здоровья
- `/actuator/metrics` - список метрик
- `/actuator/prometheus` - метрики в формате Prometheus

## Удаление

```bash
# Удалить приложение
kubectl delete -f k8s/

# Удалить мониторинг
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring

# Остановить Minikube
minikube stop
```

## Дополнительные ресурсы

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## Автор

Проект выполнен в рамках итогового задания по оркестрации и контейнеризации.

## Лицензия

MIT
