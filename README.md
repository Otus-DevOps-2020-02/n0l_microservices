# n0l_microservices
n0l microservices repository

[![Build Status](https://travis-ci.com/Otus-DevOps-2020-02/n0l_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2020-02/n0l_microservices)

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

- 



docker build -t xmanchan/post:1.0 ./post-py

docker build -t xmanchan/comment:1.0 ./comment

docker build -t xmanchan/ui:1.0 ./ui









docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest

docker run -d --network=reddit --network-alias=post xmanchan/post:1.0

docker run -d --network=reddit --network-alias=comment xmanchan/comment:1.0

docker run -d --network=reddit -p 9292:9292 xmanchan/ui:1.0

