# n0l_microservices
n0l microservices repository

[![Build Status](https://travis-ci.com/Otus-DevOps-2020-02/n0l_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2020-02/n0l_microservices)

#### ex.28

1. Helm и Helm3 - пакетный менеджер для Kubernetes (tiller, Charts, templates, _helpers.tpl)
2. GitLab + Kubernetes (Депрлой в разные окружения, среды production и staging)
3. Правильный пайплайн
4. Триггеры

#### ex.27 (по списку 26)

1. Повторили сетевое взаимодействие подов 

   - ClusterIP - дойти до сервиса можно только изнутри кластера, kube-dns

   - nodePort - клиент снаружи кластера приходит на опубликованный порт

   - LoadBalancer - клиент приходит на облачный (aws elb, Google gclb) ресурс балансировки

   - ExternalName - внешний ресурс по отношению к кластеру

2. Ingress - набор правил внутри кластера Kubernetes, предназначенных для того, чтобы входящие подключения могли достичь сервисов (Services). 

3. Настрока TLS

4. NetworkPolicy - инструмент для декларативного описания потоков трафика. Отметим, что не все сетевые плагины поддерживают политики сети.

5. Хранения данных

   - Volume emptyDir
   - Volume PersistentDisk
   - PersistentVolume
     - PersistentVolumeClaim
     - PVC + StorageClass
     - dynamic PVC

#### ex.26 (по списку 27)

1. Разворачиваем Kubernetes локально с помощью minikube (подробный гайд)
2. Запуск приложения в minikube (редактирование deployment манефестов, настройка сети, настройка namespace)
3. Dashboard плангин в minikube
4. Разворачиваем Kubernetes в Google Kubernetes Engine
5. Запуск приложения в GKE
6. Dashboard в GKE
7. Развернуть Kubenetes-кластер в GKE с помощью Terraform

#### ex.25

1. Знакомство с Kubernetes. Основные сущьности
2. Прохождение курса по развертыванию вручную  https://github.com/kelseyhightower/kubernetes-the-hard-way

#### ex.23

1. Логирование Docker контейнеров c помощью Elastic стека (ElasticSearch, Fluentd, Kibana)
2. Структурированные логи (Фильтры, поиск по полям)
3. Неструктурированные логи (Парсинг с помощью регулярных выражений, grok-шаблоны)
4. Работа с Zipkin отслеживание запроса

#### ex.21

1. Мониторинг Docker контейнеров с помощью [cAdvisor](https://github.com/google/cadvisor)
2. Grafana, работа с готовыми дашбордами, создание собственных
3. Гистограммы, чуть-чуть статистики
4. Алертинг через Alertmanager
5. Интеграция алертинга со slack
6. Поправил make файл. добавил сборку alertmanager
7. https://hub.docker.com/u/xmanchan

#### ex.20

1. Развернули систему мониторинга Prometheus
2. Посмотрели как можно монитрить состояние сервисов
3. Exporters blackbox и whitebox
4. Мониторинг mongoDB с помощью percona/mongodb_exporter
5. Настройка монитонга сервиов с помощью prom/blackbox-exporter
6. Как писать Makefile
7. https://hub.docker.com/u/xmanchan

#### ex.19

1. Развертывание и первичная настройка gitlab

2. Основные понятия

3. Настроить сборку контейнера с приложением reddit

   - Настроить сборку контейнера с приложением reddit ($CI_PIPELINE_ID - номер запускаемого пайплайна. С новым номером в докерхаб будет выкладываться новый образ.)
   - Настроить с поднятие сервера в GCP (с помощью **terraform terraform apply --var-file terraform.tfvars.example**)
   - Задеплоить приложение. C помощью ansible два плейбука
     - ansible-playbook install-docker.yml
     - ansible-playbook run-docker-image.yml --extra-vars "version=2.$CI_PIPELINE_ID hub_login=$DOCKER_HUB_LOGIN hub_password=$DOCKER_HUB_PASSWORD"

   Вся инфраструктура разворачиватеся при помощи терраформ, провижининг осуществляется при помощи ансибл. Для работы с терраформом был создан сервисный аккаунт. Как создать аккаунт [1](https://cloud.google.com/compute/docs/access/service-accounts), [2](https://www.magellanic-clouds.com/blocks/en/guide/create-gcp-service-account-key/). [Работа с ключом](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)

4. Интеграция gitlab со slack 

   https://docs.gitlab.com/ee/user/project/integrations/slack.html

5. Автоматизировать регистрацию раннеров на gitlab

   - Развертывание VM происходит при помощи terraform все файлы лежат в папке gitlab-ci
   - Провижининг происходит при помощи ansible два плейбука
     - Первый устанавливает docker (ansible-playbook install-docker.yml)
     - Второй скачивает и запускает и регистрирует образ с раннером  (ansible-playbook register-runner.yml --extra-vars '{"gitlab_ip":"http://35.187.64.198/","token":"Nr4pkYnrxozyxxxXXXxxx"}')

#### ex.17

1. работа с сетями в docker (none, host, bridge)

2. запустили наш проект в 2-х bridge сетях. Так , чтобы сервис ui не имел доступа к базе данных

3. цепочка DOCKER в iptables на хостовой машине

4. Docker-compose (в .env файл можно сложить переменные)

5. COMPOSE_PROJECT_NAME=xxx - название проекта (по умолчанию имя директории)

6. docker-compose.override.yml файл для внесения изменений

   

#### ex.16

1. правила написание docker файла
2. оптимизация docker образов
3. пазбивка приложения на микросервисы
4. переопределиение имен хостов в ENV переменных
5. работа с Alpine Linux
6. работа с volume

#### ex.15

1. основные команды docker
2. как работает docker внутри (изоляция процессов, изоляция сети, изоляция пользователей)
3. работа с docker machine (управление контейнером на машине в облаке GCP)
4. выгрузка образа на docker hub
5. поднять несколько (количество регулируется) инстансов с помощью terraform
6. c помощью playbook ansible установить docker c  помощью другого запустить контейнер из docker hub
7. пакера, который делает образ с уже установленным Docker



