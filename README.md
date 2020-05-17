# n0l_microservices
n0l microservices repository

[![Build Status](https://travis-ci.com/Otus-DevOps-2020-02/n0l_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2020-02/n0l_microservices)

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

docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b docker-host



travis encrypt "devops-team-otus:8wHFpKna2WWZqbOSwhTk1B3L#n0l_microservices" --add notifications.slack.rooms --co

