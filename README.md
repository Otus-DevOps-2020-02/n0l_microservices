# n0l_microservices
n0l microservices repository

[![Build Status](https://travis-ci.com/Otus-DevOps-2020-02/n0l_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2020-02/n0l_microservices)

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



