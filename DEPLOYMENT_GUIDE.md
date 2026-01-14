# Руководство по развертыванию

## Пошаговая инструкция

### Шаг 1: Установка Minikube

#### macOS
```bash
brew install minikube
```

#### Linux
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

#### Windows
Скачайте установщик с https://minikube.sigs.k8s.io/docs/start/

### Шаг 2: Запуск Minikube

```bash
# Запуск кластера с 2 нодами
minikube start --cpus=4 --memory=8192mb --nodes=2

# Включение необходимых аддонов
minikube addons enable ingress
minikube addons enable metrics-server

# Проверка статуса
minikube status
kubectl get nodes
```

**Скриншот:** Выполните команду `minikube status` и сделайте скриншот вывода.

### Шаг 3: Сборка приложения

```bash
# Сборка Java приложения
./mvnw clean package -DskipTests

# Проверка размера JAR файла
ls -lh target/*.jar
```

**Скриншот:** Выполните команду `ls -lh target/*.jar` и сделайте скриншот.

### Шаг 4: Сборка Docker образа

```bash
# Сборка образа
docker build -t sentiment-analyzer:latest .

# Проверка размера образа (должен быть < 150MB)
docker images sentiment-analyzer:latest

# Загрузка образа в Minikube
minikube image load sentiment-analyzer:latest
```

**Скриншот:** Выполните команду `docker images sentiment-analyzer:latest` и сделайте скриншот с размером образа.

### Шаг 5: Развертывание в Kubernetes

```bash
# Применение манифестов
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Проверка статуса развертывания
kubectl get pods -l app=sentiment-analyzer
kubectl get services
kubectl get ingress
kubectl get hpa
```

**Скриншоты:**
- `kubectl get pods -l app=sentiment-analyzer` - должно быть 3 пода
- `kubectl get services` - должен быть сервис типа LoadBalancer
- `kubectl get ingress` - должен быть Ingress
- `kubectl get hpa` - должен быть HPA

### Шаг 6: Тестирование API

⚠️ **Важно:** Все эндпоинты находятся по пути `/api/...`. Корневой путь `/` не имеет маппинга.

**Вариант 1: Через port-forward (рекомендуется для тестирования)**

```bash
# В одном терминале
kubectl port-forward svc/sentiment-analyzer-service 8080:80

# В другом терминале (или после Ctrl+Z и bg)
curl http://localhost:8080/api/health
curl "http://localhost:8080/api/sentiment?text=I%20love%20this%20application"
curl "http://localhost:8080/api/sentiment?text=I%20hate%20this"
```

**Вариант 2: Через minikube service**

```bash
# Получить URL
SERVICE_URL=$(minikube service sentiment-analyzer-service --url)

# Тестирование API
curl $SERVICE_URL/api/health
curl "$SERVICE_URL/api/sentiment?text=I%20love%20this%20application"
curl "$SERVICE_URL/api/sentiment?text=I%20hate%20this"

# Или напрямую
curl $(minikube service sentiment-analyzer-service --url)/api/health
curl "$(minikube service sentiment-analyzer-service --url)/api/sentiment?text=I%20love%20this%20application"
```

**Скриншот:** Выполните curl команды и сделайте скриншот ответов.

### Шаг 7: Установка Prometheus и Grafana

```bash
# Добавление Helm репозитория
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Установка kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --wait

# Применение ServiceMonitor
kubectl apply -f k8s/service-monitor.yaml

# Ожидание готовности Grafana
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
```

**Скриншот:** Выполните `kubectl get pods -n monitoring` и сделайте скриншот.

### Шаг 8: Доступ к Grafana

```bash
# Получение пароля администратора
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode

# Проброс порта
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Откройте http://localhost:3000 в браузере:
- Username: `admin`
- Password: (из команды выше)

**Скриншот:** Сделайте скриншот дашборда Grafana с метриками приложения.

### Шаг 9: Проверка метрик Prometheus

```bash
# Проброс порта для Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Проверка метрик приложения
kubectl port-forward svc/sentiment-analyzer-service 8080:80
curl http://localhost:8080/actuator/prometheus
```

**Скриншот:** Выполните `curl http://localhost:8080/actuator/prometheus` и сделайте скриншот вывода.

### Шаг 10: Тестирование HPA

```bash
# Создание нагрузки
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- \
  /bin/sh -c "while sleep 0.01; do wget -q -O- http://sentiment-analyzer-service/api/sentiment?text=test; done"

# В другом терминале наблюдение за масштабированием
watch kubectl get hpa sentiment-analyzer-hpa
watch kubectl get pods -l app=sentiment-analyzer
```

**Скриншот:** Сделайте скриншот HPA и подов во время масштабирования.

## Проверочный список

- [ ] Minikube установлен и запущен
- [ ] Docker образ собран и размер < 150MB
- [ ] Deployment с 3 репликами развернут
- [ ] Service типа LoadBalancer создан
- [ ] Ingress настроен
- [ ] HPA работает
- [ ] Prometheus установлен и собирает метрики
- [ ] Grafana установлен и показывает дашборды
- [ ] API отвечает корректно
- [ ] Масштабирование работает

## Устранение проблем

### Проблема: Поды не запускаются
```bash
# Проверить логи
kubectl logs -l app=sentiment-analyzer

# Проверить события
kubectl get events --sort-by='.lastTimestamp'
```

### Проблема: Образ не найден
```bash
# Убедиться, что образ загружен в Minikube
minikube image ls | grep sentiment-analyzer

# Если нет, загрузить заново
minikube image load sentiment-analyzer:latest
```

### Проблема: Ingress не работает
```bash
# Проверить статус Ingress контроллера
minikube addons list | grep ingress

# Если не включен
minikube addons enable ingress
```

### Проблема: Prometheus не собирает метрики
```bash
# Проверить ServiceMonitor
kubectl get servicemonitor -n monitoring

# Проверить метки подов
kubectl get pods -l app=sentiment-analyzer --show-labels
```
