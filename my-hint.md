# Kubernetes

Описание пополню по мере

Для настройки и тестов хорошо подходит локальный кубер на основе minikube.  Описанное в манифестах приложение можно легко развернуть на любом кластере.

Сменить контекст: 

```
kubectl config get-contexts                          # показать список контекстов
kubectl config current-context                       # показать текущий контекст (current-context)
kubectl config use-context my-cluster-name           # установить my-cluster-name как контекст по умолчанию
```

Ingress – это набор правил внутри кластера Kubernetes, предназначенных для того, чтобы входящие подключения могли достичь сервисов (Services) Сами по себе Ingress’ы это просто правила. Для их применения нужен Ingress Controller.

# Логирование

Логи должны иметь заданную (единую) структуру и содержать необходимую для нормальной эксплуатации данного сервиса информацию о его работе

Неструктурированные логи отличаются отсутствием четкой структуры данных. Также часто бывает, что формат лог-сообщений не подстроен под систему централизованного логирования, что существенно увеличивает затраты вычислительных и временных ресурсов на обработку данных и выделение нужной информации.  Когда приложение или сервис не пишет структурированныелоги, приходится использовать старые добрые регулярные выражения для их парсинга в /docker/fluentd/fluent.conf. Для облегчения задачи парсинга вместо стандартных регулярок можно использовать grok-шаблоны.

- ElasticSearch (TSDB и поисковый движок для хранения данных)
- Logstash (для агрегации и трансформации данных) В ДЗ тут использовался Fluentd
- Kibana (для визуализации)

Для настройки fluentd потребуетс я конфиг файл пример

```
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<filter service.post>
@type parser
format json
key_name log
</filter>

<filter service.ui>
  @type parser
  key_name log
  format grok
  grok_pattern %{RUBY_LOGGER}
</filter>

<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  key_name message
  reserve_data true
</filter>

<match *.**>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    logstash_format true
    logstash_prefix fluentd
    logstash_dateformat %Y%m%d
    include_tag_key true
    type_name access_log
    tag_key @log_name
    flush_interval 1s
  </store>
  <store>
    @type stdout
  </store>
</match>

```



#### Zipkin

Удобный инструмент для распределенного трейсинга. Показывет наглядно сколько времени ушло на выполнение запроса какие проиложение учавствовали в выполненни запроса. Где тормоза.



# Make

Очень полезная однако утилита, которая позволяет автоматизировать рутину.

Если кратко пишутся скрипты, делятся на части и добавляются ключи для вызова итих кусочков.

Можно очень гибко запускать часть скрипта не используя ключи в баш скриптах

http://rus-linux.net/nlib.php?name=/MyLDP/algol/gnu_make/gnu_make_3-79_russian_manual.html



# Prometeus

#### Установка

1. $ gcloud compute firewall-rules create prometheus-default --allow tcp:9090
   $ gcloud compute firewall-rules create puma-default --allow tcp:9292
2. $ export GOOGLE_PROJECT=_ваш-проект_
3. $ docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b docker-host
4. $ eval $(docker-machine env docker-host)
5. $ docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus:v2.1.0 (Возможно перед этим потребуется $ docker login)
6. http://ext-ip:9090 (ext-ip можно узнать $docker-machine ip docker-host)

#### Понятия

**prometheus_build_info**{**branch**="HEAD",**goversion=**"go1.9.1",**instance=**"localhost:9090", **job=**"prometheus", **revision=**"3a7c51ab70fc7615cd318204d3aa7c078b7c5b20",version="1.8.1"} **1**

- **prometheus_build_info** - название метрики, идентификатор собранной информации.
- **branch**, **goversion**, **instance**, итд - лейбл, добавляет метаданных метрике, уточняет ее. Использование лейблов дает нам возможность не ограничиваться лишь одним названием метрик для идентификации получаемой информации. Лейблы содержаться в {} скобках и представлены наборами "ключ=значение".
- 1 - значение метрики, численное значение метрики, либо NaN, если значение недоступно

Targets (цели) - представляют собой системы или процессы, за которыми следит Prometheus. Помним, что Prometheus является pull системой, поэтому он постоянно делает HTTP запросы на имеющиеся у него адреса (endpoints). Посмотрим текущий список целей

#### Настройка

Вся конфигурация Prometheus, в отличие от многих других систем мониторинга, происходит через файлы конфигурации и опции командной строки. Мы определим простой конфигурационный файл для сбора метрик с наших микросервисов. В директории monitoring/prometheus создайте файл prometheus.yml со следующим содержимым

```yml
---
global:
  scrape_interval: '5s'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets:
        - 'localhost:9090'

  - job_name: 'ui'
    static_configs:
      - targets:
        - 'ui:9292'

  - job_name: 'comment'
    static_configs:
      - targets:
        - 'comment:9292'
```

В директории prometheus собираем Docker образ:

$ export USER_NAME=username
$ docker build -t $USER_NAME/prometheus .

Где USER_NAME - ВАШ логин от DockerHub.

#### Healthcheck

Healthcheck-и представляют собой проверки того, что наш сервис здоров и работает в ожидаемом режиме. В нашем случае healthcheck выполняется внутри кода микросервиса и выполняет проверку того, что все сервисы, от которых зависит его работа, ему доступны. Если требуемые для его работы сервисы здоровы, то healthcheck проверка возвращает status = 1, что соответсвует тому, что сам сервис здоров. Если один из нужных ему сервисов нездоров или недоступен, то проверка вернет status = 0.

#### Exporters

Программа, которая делает метрики доступными

для сбора Prometheus. Дает возможность конвертировать метрики в нужный для Prometheus формат. Используется когда нельзя поменять код приложения Примеры: PostgreSQL, RabbitMQ, Nginx, Node exporter, cAdvisor

Предварительно нужно запустить экспортер, можно в контейнере или на хосте. Также экспортеры делятся по типу whitebox - умеют извлекать попадать внутрь приложения и извлекать метриеки. Blackbox -  могут пощупать приложение снаружи и определить приходит ли код 200 по http и слущает ли приложение на определенном порту

Экспортеры добавляются в prometheus.yml

Подробно про blackbox тут https://kamaok.org.ua/?p=3281





# GitLab

Комбайн, который позволяет организовать весь процесс разработки, настроить автоматизацию по тестированию и деплою.

Поскольку в каждом проекте есть толлько один файл .gitlab-ci.yml то, там где используется монорепа могут быть проблемы. Так как по существу пайплайны пишутся под один проект

- Каждый проект в Gitlab CI принадлежит к группе проектов

- В проекте может быть определен CI/CD пайплайн
- Задачи (jobs) входящие в пайплайн должны исполняться на runners

#### Установка

Описана в лекции

#### Runner

По сути площадка для запуска пайплайна

К проекту можно подключить несколько раннеров и на основании тегов рулить какой раннер запускать

#### .gitlab-ci.yml

файл в котором последовательно описываются команды

[Хорошая статься по введению в гитлаб](https://habr.com/ru/company/softmart/blog/309380/)

В гитлаб можно прописать для проета переменные в специальных полях и использовать их как переменные окружения. Есть два типа переменных var и file

Из косяков - передача ssh оказывается сложной, при вытаскивании его из переменной окружения знаки переноса строк заменяются на пробелы. В итоге ssh не цепляется, ansible не отрабатывает.

#### 19 ДЗ*

#### Настроить сборку контейнера с приложением reddit

1. Настроить сборку контейнера с приложением reddit ($CI_PIPELINE_ID - номер запускаемого пайплайна. С новым номером в докерхаб будет выкладываться новый образ.)
2. Настроить с поднятие сервера в GCP (с помощью **terraform terraform apply --var-file terraform.tfvars.example**)
3. Задеплоить приложение. C помощью ansible два плейбука
   - ansible-playbook install-docker.yml
   - ansible-playbook run-docker-image.yml --extra-vars "version=2.$CI_PIPELINE_ID hub_login=$DOCKER_HUB_LOGIN hub_password=$DOCKER_HUB_PASSWORD"

Вся инфраструктура разворачиватеся при помощи терраформ, провижининг осуществляется при помощи ансибл. Для работы с терраформом был создан сервисный аккаунт. Как создать аккаунт [1](https://cloud.google.com/compute/docs/access/service-accounts), [2](https://www.magellanic-clouds.com/blocks/en/guide/create-gcp-service-account-key/). [Работа с ключом](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)

#### Интеграция gitlab со slack 

https://docs.gitlab.com/ee/user/project/integrations/slack.html

#### Автоматизировать регистрацию раннеров на gitlab

1. Развертывание VM происходит при помощи terraform все файлы лежат в папке gitlab-ci
2. Провижининг происходит при помощи ansible два плейбука
   - Первый устанавливает docker (ansible-playbook install-docker.yml)
   - Второй скачивает и запускает и регистрирует образ с раннером  (ansible-playbook register-runner.yml --extra-vars '{"gitlab_ip":"http://35.187.64.198/","token":"Nr4pkYnrxozyty7y4-rU"}')

#### Ссылки

https://docs.gitlab.com/ee/ci/yaml/#before_script-and-after_script

https://docs.gitlab.com/ce/ci/docker/using_docker_build.html

https://docs.gitlab.com/ee/ci/variables/predefined_variables.html

https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html

https://docs.ansible.com/ansible/latest/modules/gitlab_runner_module.html

https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html

https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/



# Docker-compose

Утилита для управления группой контейнеров

https://habr.com/ru/company/otus/blog/337688/

####  установка

pip3 install docker-compose

#### Пример файла

```
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - post_db:/data/db
    networks:
      - back_net
  ui:
    build: ./ui
    image: ${USERNAME}/ui:${VER}
    ports:
      - 9292:${EXT_PORT}/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USERNAME}/post:${VER}
    networks:
      - front_net
      - back_net
  comment:
    build: ./comment
    image: ${USERNAME}/comment:${VER}
    networks:
      - front_net
      - back_net

volumes:
  post_db:

networks:
  front_net:
  back_net:
  reddit:
```

Все переменые можно опредедить через export USERNAME=<your-login> или записть в файл .env

В файле docker-compose.override.yml можно вносить изменения (чтобы допустим иметь несколько окружений)

Docker Compose по умолчанию читает два файла: docker-compose.yml и docker-compose.override.yml. В файле docker-compose-override.yml можно хранить переопределения для существующих сервисов или определять новые. Чтобы использовать несколько файлов (или файл переопределения с другим именем), необходимо передать -f в docker-compose up (порядок имеет значение):

```
$ docker-compose up -f my-override-1.yml my-overide-2.yml
```

Более подробно тут: https://habr.com/ru/company/otus/blog/337688/



#### Файл окружения


Для гарантии передачи переменной среды, необходимо хранить её в файле среды. Назовите файл .env и сохраните в рабочей директории. Docker Compose игнорирует пустые строки (используйте их для лучшей читаемости) и код, начинающийся с # (то есть комментарии). Вы можете присвоить переменные для дальнейшей подстановки, а также задать переменные Compose CLI:

```
COMPOSE_API_VERSION
COMPOSE_FILE
COMPOSE_HTTP_TIMEOUT
COMPOSE_PROJECT_NAME
DOCKER_CERT_PATH
DOCKER_HOST
DOCKER_TLS_VERIFY
```


Пример файла среды:

```
# ./.env 
# для нашей промежуточной среды

COMPOSE_API_VERSION=2
COMPOSE_HTTP_TIMEOUT=45
DOCKER_CERT_PATH=/mycerts/docker.crt
EXTERNAL_PORT=5000
```

# Docker

#### Установка

- Ubuntu Linux: https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/
- Mac OS: https://download.docker.com/mac/stable/Docker.dmg
- Windows: https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe



#### Основные команды

```bash
$ docker version
$ docker info
$ docker run hello-world # произошло следующее:
#docker client запросил у docker engine запуск container из image hello-world
#docker engine не нашел image hello-world локально и скачал его с Docker Hub
#docker engine создал и запустил container из image hello-world и передал docker client вывод stdout контейнера
$ docker ps -a
$ docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Names}}"
$ docker images
$ docker start <u_container_id> # запускает остановленный(уже созданный) контейнер
$ docker attach <u_container_id> # подсоединяет терминал к созданному контейнеру
$ docker  create hello-world # используеться, когда не нужно стартовать контейнер сразу
$ docker exec -it <u_container_id> bash # запускает новый процесс внутри контейнера с приложением
$ docker commit <u_container_id> yourname/ubuntu-tmp-file # Создает image из контейнера контейнер при этом остается запущенным
$ docker inspect <u_container_id>
$ docker inspect <u_image_id>
$ docker kill $(docker ps -q) # сразу убивает процесс
$ docker stop <u_container_id> # посылает SIGTERM, и через 10 секунд(настраивается) посылает SIGKILL
$ docker system df # Отображает сколько дискового пространства занято образами, контейнерами и volume’ами
$ docker rm <u_container_id> # удаляет контейнер, можно добавить флаг -f, чтобы удалялся работающий container(будет послан sigkill)
$ docker rmi <u_image_id> #удаляет image, если от него не зависят запущенные контейнеры
$ docker rm $(docker ps -a -q) # удалит все незапущенные контейнеры
$ docker rmi $(docker images -q)
```

- Если не указывать флаг --rm при запуске docker run, то после остановки контейнер вместе с содержимым остается на диске
- Docker run
  - -i – запускает контейнер в foreground режиме (docker attach)
  - -d – запускает контейнер в background режиме
  - -t создает TTY
  - $ docker run -it ubuntu:16.04 bash
  - $ docker run -dt nginx:latest

#### Секреты и чувствительные данные

через ENV не рекомендуют, так как их можно узнать взломавши контейнер либо хост

https://stackoverflow.com/questions/30494050/how-do-i-pass-environment-variables-to-docker-containers

#### Docker machine

**Docker machine на macOS ставится отдельно!**

- docker-machine - встроенный в докер инструмент для создания хостов и установки на них docker engine. Имеет поддержку облаков и систем виртуализации (Virtualbox, GCP и др.)
- Команда создания - docker-machine create <имя>. Имен может быть много, переключение между ними через eval $(docker-machine env <имя>). Переключение на локальный докер - eval $(docker-machine env --unset). Удаление - docker-machine rm <имя>.
- docker-machine создает хост для докер демона со указываемым образом в --googlemachine-image, в ДЗ используется ubuntu-16.04. Образы которые используются для построения докер контейнеров к этому никак не относятся.
- Все докер команды, которые запускаются в той же консоли после eval $(docker-machine env <имя>) работают с удаленным докер демоном в GCP.

```bash
# Создать инстанс с docker engine в облаке используя docker machine
$ docker-machine create --driver google \
--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
--google-machine-type n1-standard-1 \
--google-zone europe-west1-b \
docker-host
# посмореть список инстансов
$ docker-machine ls
```

#### Последовательность для запуска ВМ с докером в GCP

- export GOOGLE_PROJECT=_ваш-проект_ (либо создать файл .env)
- docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b --google-disk-size 100 gitlab-ci
- docker-machine ls
- eval $(docker-machine env docker-host)
- поработали
- eval $(docker-machine env --unset)
- docker-machine rm <имя>

# Molecule

https://habr.com/ru/post/351974/

Инструмент для тестирования ролей в Ansble. В версии 2.22 есть гораздо больше провайдеров для того чтобы развернуть окружение. В версии 3.03 их всего 3.

Устанавливать её рекомедуется в виртуальное окружение

#### Virtual Environments

https://docs.python-guide.org/dev/virtualenvs/

Очень полезная статья по настроке виртуального окружения virtualenv

Для корректной работы нужно:

- Использовать **--user** для установки пакетов локально для пользователя
- Использовать pip3 для работы с python 3 версии
- Добавить в переменную PATH="$PATH:/path/to/dir" путь к питону "python3 -m site --user-base"

#### Команды

```bash
$ molecule --version
$ molecule init scenario --scenario-name default -r db -d vagrant
# Нужно добавлять scenario, если мы создаем тест для существующей роли
# Или просто init для новой роли
# -d vagrant - драйвер (с 3й версии их количество сильно порезали)
$ molecule create создает виртуальные машины (выполняется в папке с ролью например ansible/roles/db)
$ molecule destroy -f удалет VM
$ molecule list посмотреть список созданных VM
$ molecule login -h instance подключиться внутр машины и с именем ssh

$ molecule converge Применим playbook.yml, в котором вызывается наша роль к
созданному хосту
$ molecule verify Прогнать тесты
```



#### тесты

лежат тут: db/molecule/default/tests/test_default.py

список модулей от testinfra https://testinfra.readthedocs.io/en/latest/modules.html



# Vagrant

Инструмент для автоматизации разработки:

- Создание, настройка и удаление локальных окружений
- Providers (VirtualBox, Hyper-V, VMware, Docker, …)
- Provisioners (Ansible, Chef, Puppet, Salt, Shell, …)
- Плагины

#### Config

Пример конфигурационного файла:

```ini
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "10.10.10.10"
  end
  
  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "10.10.10.20"
  end
end
```

#### Команды

```
$ vagrant up # создать инфраструктуру
$ vagrant box list # списока образов скачанных на локальную машину
$ vagrant status # статус  VM
$ vagrant ssh appserver # подключиться к VM
$ vagrant provision dbserver # запуск провжинера на VM
```

#### Vagrant Cloud

Хранилище образов

https://app.vagrantup.com/boxes/search

#### Провижинеры

Vagrant поддерживает большое количество провижинеров, которые позволяют автоматизировать процесс конфигурации созданных VMs с использованием популярных инструментов управления конфигурацией и обычных скриптов на bash.

https://www.vagrantup.com/docs/provisioning/

Пример ansible provision

```
db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
end
```



# Ansible

#### Установка

https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#from-pip

Судя по инструкции, приоритетный метод - через pip install ansible --user. Но по умолчанию в macOS в $PATH нету пути ~/Library/Python/2.7/lib/python/site-packages/ansible - а именно туда ставится ansible. Вариант - использовать pip3

```bash
$ ansible --version
```

Ансибл управляет удаленным хостом с через ssh c соединение, клиент ему не нужен. Для выполнения различных действий используются модули (их достаточно много). Плохой практивкой считается использовать bash  скрипты, если функционал описан в готовом модуле. У ансибл есть функция сборки аргументов (там много параметров, которые можно использовать)

#### Magic variable

Есть список переменных которые курирует ansible

- inventory_dir

#### Повышение привелегий

Директивы become и become_user можно указывать:

- Глобально

- На плейбук

- На каждый таск (блоки и т.д.)

Пишите плейбуки и роли так, чтобы действия, которым нужен root были явно выделены

#### Inventory

Хосты и группы хостов, которыми Ansible должен управлять, описываются в инвентори-файле. 

- Самый простой пример:

  ```ini
  appserver ansible_host=35.195.186.154 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser
  ```

  где appserver - краткое имя, которое идентифицирует данный хост.

- Если используется файл ansible.cfg, то можно удалить избыточную информацию

  ```ini
  appserver ansible_host=35.195.74.54
  dbserver ansible_host=35.195.162.174
  ```

- В инвентори файле мы можем определить группу хостов для управления конфигурацией сразу нескольких хостов. Список хостов указывается под названием группы, каждый новый хост указывается в новой строке. В нашем случае, каждая группа будет включать в себя всего один хост.

  ```ini
  [app] # ⬅ Это название группы
  appserver ansible_host=35.195.74.54 # ⬅ Cписок хостов в данной группе
  [db]
  dbserver ansible_host=35.195.162.174
  ```

  Теперь мы можем управлять не отдельными хостами, а целыми группами, ссылаясь на имя группы: $ ansible app -m ping

- Начиная с Ansible 2.4 появилась возможность использовать YAML для inventory https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html

  ```yaml
  app:
    hosts:
      appserver:
        ansible_host: 35.190.196.109
  
  db:
    hosts:
      dbserver:
        ansible_host: 104.155.9.218
  ```

Использовать самописный инвентори становится неудобно, поэтому перешел на плагин, оказалось он довольно легко настравается:

```
[inventory]
enable_plugins = gcp_compute
```



#### ansible.cfg

Для того чтобы управлять инстансами нам приходится вписывать много данных в наш инвентори файл. К тому же, чтобы использовать данный инвентори, нам приходится каждый раз указывать его явно, как опцию команды ansible. Многое из этого мы можем определить в конфигурации Ansible.

```ini
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```

Загружаются все файлы в group_vars для хоста

Ansible загружает все переменные хоста из файлов групп, которым он принадлежит в инвентори, даже если группа в плейбуке не участвует в сценарии. Это может привести к неоднозначности значения переменных. Так что, используйте префиксы в именах переменных для предотвращения такой ситуации



#### Модули

```bash
$ ansible appserver -i ./inventory -m ping
```

- -m ping - вызываемый модуль
- -i ./inventory - путь до файла инвентори
- appserver - Имя хоста, которое указали в инвентори, откуда Ansible yзнает, как подключаться к хосту

Модуль command выполняет команды, не используя оболочку (sh, bash), поэтому в нем не работают перенаправления потоков и нет доступа к некоторым переменным окружения.

#### Playbook

Последовательное выполнение нескольких модулей (сценарий)

```
---
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/appuser/reddit
```

#### Dynamic inventory

- https://medium.com/@Nklya/динамическое-инвентори-в-ansible-9ee880d540d6

Для описания инвентори Ansible использует форматы файлов INI и YAML. Также поддерживается формат JSON. При этом, Ansible поддерживает две различных схемы JSON-inventory: одна является прямым отображением YAML-формата (можно сделать через конвертер YAML <-> JSON), а другая используется для динамического inventory.

- Самописный скрипт

  [https://medium.com/@Nklya/%D0%B4%D0%B8%D0%BD%D0%B0%D0%BC%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5-%D0%B8%D0%BD%D0%B2%D0%B5%D0%BD%D1%82%D0%BE%D1%80%D0%B8-%D0%B2-ansible-9ee880d540d6](https://medium.com/@Nklya/динамическое-инвентори-в-ansible-9ee880d540d6) 
  Для работы с динамическим инвентори нужно написать скрипт, который на выходе выдает json формата как в статье Скрипт dynamic-inventory.py - ходит в gcp, парсит имена хостов и ip адреса и выдает форматированный json

- gce.py и другие готовые утилиты здесь не рассматривается в качестве решения https://github.com/ansible/ansible/blob/stable-2.7/contrib/inventory/gce.py

- плагин gcp_compute

#### Шаблоны

Используется шаблонизатор Jinja2
Обычно шаблоны именуют с расширением j2
Переменные в шаблонах вызываются без кавычек

https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html

Пример шаблона:

```jinja2
# network interfaces
net:
  port: 27017
  bindIp: {{ mongodb_listen_ip }} # <-- Использование переменных
# Replication params
{% if mongodb_replication_replset -%} # <-- Условный оператор на основе переменных
replication:
  replSetName: {{ mongodb_replication_replset }}
{% endif %}
```

Пример вызова шаблона:

```yaml
- name: Create mongod.conf file for MongoDB
  template:
    src: templates/mongodb/mongod.conf.j2
    dest: /etc/mongod.conf
```

#### Handlers

https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html#handlers-running-operations-on-change

-  Это задачи, которые вызываются другими модулями через инструкцию notify. Например, перезагрузка сервиса, если изменилась конфигурация

- В норме, хэндлер вызывается, если основная задача имеет статус CHANGED

- Каждый вызванный хэндлер выполняется только один раз, в конце выполнения play (независимо от того, сколько раз сработал notify для этого хэндлера)

- На один хэндлер могут ссылаться несколько задач

- Задача-хэндлер может вызываться по нескольким событиям (через атрибут listen)

- На вызов хэндлеров не влияют параметры командной строки --tags или --skip-tags

- Принудительное выполнение хендлера возможно при помощи модуля meta

  ```
  meta: flush_handlers
  ```

- Хэндлеры подключенных ролей вызываются в конце сценария, вместе с остальными (а не после применения задач роли)

- Можно использовать include и import для хэндлеров.

#### Ansible Vault

https://docs.ansible.com/ansible/latest/vault.html

- Консольная утилита для работы с секретными данными (сертификаты, приватные ключи и т.д.)
- Переменные можно подключать через vars_files
- Для более сложных случаев пользуйтесь Hashicorp Vault и аналогами
- Позволяет хранить в общих репозиториях файлы, в которых содержится приватная информация (пароли, токены)
- Использование зашифрованных переменных полностью прозрачно. В процессе выполнения ansible получает к ним доступ. Файлы на диске остаются зашифрованными.

Чтобы зашифровать существующий файл выполняем команды:

```bash
$ ansible-vault --vault-id dev@prompt encrypt --encrypt-vault-id dev secrets.yml
```

Файл с секретами будет запаролен, в будущем, когда мы захотим выполнить playbook с использованием secrets.yml, необходимо передать параметр --ask-vault-pass Либо мы можем указать в ansible.cfg опцию vault_password_file, которая указывает на файл с ключом. Пример:

```bash
$ ansible-playbook myplaybook.yml --ask-vault-pass
```

Можно зашифровать только некоторые строки в файле:

```bash
$ ansible-vault encrypt_string --vault-id dev@password --encrypt-vault-id dev 'foooodev' --name 'the_dev_secret'
```

#### Tags

- Ansible позволяет указывать метки (tags) в плейбуках (для импортированных сценариев и задач)
- Для каждого сценария и задачи может быть установлено более одной метки
- Метки можно использовать для запуска определенных этапов сценария (ключ --tags)
- Либо можно пропускать части сценария по меткам (ключ --skip-tags)

#### Include_* VS Import__*

- Import_* выполняется пред исполнением playbook
- Include_* в момент выполнения (если мы допустим не знаем заранее ip адреса машин на которых будет прокатываться playbook, то это как раз случай include)

#### Debug

- -vvvv
- Пошаговое выполнение --step
- Модуль debug
- Стратегия debug - вызывает отладчик PDB в случае проблем

#### Роли

Роль в Ansible – это директория с определенной структурой и YAML-файлами (Роль можно запускать только в рамках playbook)

создать структуру роли можно так:

```bash
$ ansible-galaxy init app
$ ansible-galaxy init db
```

Роль содержит:

- Таски (вызовы Ansible-модулей) и хендлеры
- Наборы переменных
- Метаданные (версии и зависимости от других ролей)
- Тесты (для локальной отладки и разработки)
- Вспомогательные файлы и шаблоны

```bash
$ tree example-role
example-role
├── README.md
├── defaults
│ └── main.yml # <- Переменные и значения по умолчанию
├── files
├── handlers
│ └── main.yml # <-- Обработчики (aka хэндлеры)
├── meta
│ └── main.yml # <-- Информация о роли и зависимостях
├── tasks
│ └── main.yml # <-- Основные задачи в роли
├── templates
│ └── mongod.conf.j2 # <-- Шаблоны конфигурации
├── tests
│ ├── inventory # <-- Сценарии и данные для тестирования
│ └── test.yml
└── vars
└── main.yml # <-- Внутренние переменные роли
```

Если роль разрастается, то код можно разбить логически на несколько yaml файлов. По умолчанию ansible читает только main.yaml а внутри него можно вставить include или import

Также,  можно делать кроссплатформенные роли используя директиву when

В плейбуках остается совсем немного: собрать роли в одно целое, обозначить хосты и переменные

Директива import_role выполняется препроцессором, до запуска плейбука.

Это значит, что:

- Не поддерживаются циклы (директива loop:)

- Зато нормально работает директива delegate_to
- Директива when: не имеет доступа к переменным групп хостов
- Таски из роли всегда выполняются в playbook (но если есть условие when: мы просто увидим кучу [SKIPPED] тасков)



#### Ansible Galaxy

https://galaxy.ansible.com/

ansible-galaxy - командная утилита для управления ролями

Скачать:

```bash
$ ansible-galaxy install geerlingguy.apache
- downloading role 'apache', owned by geerlingguy
- downloading from https://.../ansible-role/apache/2.1.1.tar.gz
- extracting geerlingguy.apache to ./geerlingguy.apache
- geerlingguy.apache (2.1.1) was installed successfully
```

Применить (пример playbook apache.yml):

```yml
- hosts: webservers
    become: true
    roles:
      - geerlingguy.apache
```

#### Окружения

Ansible нет понятия окружений (dev, stage, prod). Но в случае с Ansible они не нужны.

Типичное описание окружения состоит из:

- Списка серверов и их групп
- Средозависимых данных (переменные и файлы)
- Списка ролей и их версий, актуальных для окружения

```
environments
├── dev
│   ├── group_vars
│   │ ├── webservers # Группы хостов должны быть идентичны,
│   │ └── databases # даже если отличается схема развертывания
│   ├── requirements.yml
│   ├── credentials.yml # У окружений отдельные файлы с зашифрованными переменными
│   └── inventory
└── production
    ├── group_vars
    │ ├── webservers # Группы хостов должны быть идентичны,
    │ └── databases # даже если отличается схема развертывания
    ├── requirements.yml
    ├── credentials.yml # У окружений отдельные файлы с зашифрованными переменными
    └── inventory
```

Когда нужно развернуть инфраструктуру для какого-то окружения:

- Получаем необходимый набор ролей:

  ```bash
  $ ansible-galaxy install -r environments/<env_name>/requirements.yml
  ```

- Запускаем плейбук, который вызывает эти роли:

  ```bash
  $ ansible-playbook —i environments/<env_name>/inventory play.yml
  ```

  

# Terraform

[Terraform](https://www.terraform.io/) – это инструмент от компании Hashicorp, помогающий декларативно управлять инфраструктрой. В данном случае не приходится вручную создавать инстансы, сети и т.д. в консоли вашего облачного провайдера; достаточно написать конфигурацию, в которой будет изложено, как вы видите вашу будущую инфраструктуру. 

Взято отсюда: https://habr.com/ru/company/piter/blog/351878/

#### Установка и настройка

Устанавливается отсюда https://www.terraform.io/downloads.html

положил сюда **/usr/local/bin/terraform**

Для корректной работы с ДЗ рекомендуется указывать версию терраформа ~> 0.12.0 и провайдера google ~> 2.5.0 (~ в конфиге, значит не обращать внимания на минорные релизы, сборка перестает запускаться если отличается мажорная версия релиза)

Провайдеры Terraform являются загружаемыми модулями, начиная с версии 0.10. Для того чтобы загрузить провайдер и начать его использовать выполните следующую команду в директории terraform:

```bash
$ terraform init
```

#### Конфигурация

- terraform загружает все файлы в текущей директории, имеющие расширение .tf
  main.tf - главный конфигурационный файл

```yaml
terraform {
  # Версия terraform
  required_version = "~>0.12.19"
}
provider "google" {
  # Версия провайдера
  version = "~>2.5.0"
  # ID проекта
  project = var.project
  region  = var.region
}

resource "google_compute_instance" "app" {
  name         = "reddit-app"
  machine_type = "f1-micro"
  zone         = var.zone
  tags         = ["reddit-app"]
  # Определим параметры подключения провиженеров к VM.
  # Внутрь ресурса VM, перед определением провижинеров.
  # В данном примере мы указываем, что провижинеры,
  # определенные в ресурсе VM, должны подключаться к созданной
  # VM по SSH, используя для подключения приватный ключ
  # пользователя appuser
  connection {
    type  = "ssh"
    host  = self.network_interface[0].access_config[0].nat_ip
    user  = "appuser"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }
  # В данном случае мы говорим, провижинеру скопировать локальный файл,
  # располагающийся по указанному относительному пути (files/puma.service),
  # в указанное место на удаленном хосте
  provisioner "file" {
    source      = "./files/puma.service"
    destination = "/tmp/puma.service"
  }
  # В определении данного провижинера мы указываем
  # относительный путь до скрипта, который следует запустить на созданной VM.
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
  # В определении загрузочного диска для VM, мы
  # передаем имя семейства образа. На данном этапе используется
  # base-образ, так как дальнейшее развертывание приложения в этом
  # задании будет производиться при помощи терраформа. Также
  # можно передать полное имя образа, например "reddit-base-1514137169
  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }
  metadata = {
    # путь до публичного ключа
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
  network_interface {
    network = "default"
    access_config {}
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"
  # Название сети, в которой действует правило
  network = "default"
  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]
  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["reddit-app"]
}

resource "google_compute_project_metadata" "default" {
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}
```

- Для добавления нескольких ssh ключей в метаданные всего проекта, их нужно записывать в одну строку без пробелов. (пример ниже)
- Если через web поменять конфигурацию, затем выполнить terraform apply, то он затрет измения выполненные через web

```yaml
resource "google_compute_project_metadata" "default" {
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}appuser1:${file("/Users/xxx/.ssh/appuser1.pub")}appuser2:${file("/Users/xxx/.ssh/appuser2.pub")}"
  }
}
```

- Вынесем интересующую нас информацию - внешний адрес VM - в выходную переменную (output variable)
  outputs.tf - отдельный файл для хранения выходных переменных

```yaml
output "app_external_ip" {
  value = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
}

output "lb_external_ip" {
  value = google_compute_global_forwarding_rule.default.ip_address
}
```

- Входные переменные позволяют нам параметризировать конфигурационные файлы.
  Для того чтобы использовать входную переменную ее нужно сначала определить в одном из конфигурационных файлов. Создадим для этих целей еще один конфигурационный файл variables.tf в директории terraform

```yaml
variable project {
  description = "Project ID"
}
variable region {
  description = "Region"
  # Значение по умолчанию
  default = "us-central1"
}
variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable disk_image {
  description = "Disk image"
}
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "us-central1-f"
}
```

- Определим переменные используя специальный файл terraform.tfvars

```yaml
project          = "infra-00001"
public_key_path  = "/Users/appuser/.ssh/appuser.pub"
disk_image       = "reddit-base"
private_key_path = "/Users/appuser/.ssh/appuser"
```

- Хранение стейта. Для работы в команде удобно хранить стейт например в бакете
  

#### Команды

```
$ terraform plan
```

Покажет какие изменения будут применены. Знак "+" перед наименованием ресурса означает, что ресурс будет добавлен. Далее приведены атрибуты этого ресурса. “<computed>” означает, что данные атрибуты еще не известны terraform'у и их значения будут получены во время создания ресурса.

```
$ terraform apply
```

Применяет текущую конфигурацию. Начиная с версии 0.11 terraform apply запрашивает дополнительное подтверждение при выполнении. Необходимо добавить -auto-approve для отключения этого. Результатом выполнения команды также будет создание файла **terraform.tfstate** в директории terraform. Terraform хранит в этом файле состояние управляемых им ресурсов. Загляните в этот файл и найдите внешний IP адрес созданного инстанса.

```
$ terraform show | grep nat_ip
```

Показвает текущее состояние системы и позволет поискать

```
$ terraform refresh - позволяет обновить значения переменных
$ terraform output  - посмотреть значения переменных
$ terraform taint google_compute_instance.app  - пересоздать ресурс VM при следующем
применении изменений
$ terraform fmt - отформатировать все файлы (привести к красивому виду)
```

Перед тем как дать команду terraform'у применить изменения, хорошей практикой является предварительно посмотреть, какие изменения terraform собирается произвести относительно состояния известных ему ресурсов (tfstate файл), и проверить, что мы действительно хотим сделать именно эти изменения.

#### Provisioners

В terraform вызываются в момент создания/удаления ресурса и позволяют выполнять команды на удаленной или локальной машине. Их используют для запуска инструментов управления конфигурацией или начальной настройки системы. Используем провижинеры для деплоя последней версии приложения на созданную VM.

Внутрь ресурса, содержащего описание VM, вставьте секцию провижинера типа file, который позволяет копировать содержимое файла на удаленную машину. В нашем случае мы говорим, провижинеру скопировать локальный файл, располагающийся по указанному относительному пути (files/puma.service), в указанное место на удаленном хосте

```yaml
provisioner "file" {
  source = "files/puma.service"
  destination = "/tmp/puma.service"
}
```

Провижинеры выполняются по порядку их определения

#### Импортируем существующую инфраструктуру в Terraform

По умолчанию в новом проекте создается правило файервола, открывающее SSH доступ ко всем инстансам, запущенным в сети default (которая тоже создается по умолчанию в новом проекте).

Для корректного управления нужно:

1. Создать такое же правило в проекте (в нашем случае main.tf)

   ```yaml
   resource "google_compute_firewall" "firewall_ssh" {
     name = "default-allow-ssh"
     network = "default"
   
     allow {
       protocol = "tcp"
       ports = ["22"]
     }
   
     source_ranges = ["0.0.0.0/0"]
   }
   
   ```

2. Terraform ничего не знает о существующем правиле файервола (а всю информацию, об известных ему ресурсах, он хранит в state файле), то при выполнении команды apply terraform пытается создать новое правило файервола. Для того чтобы сказать terraform-у не создавать новое правило, а управлять уже имеющимся, в его "записную книжку" (state файл) о всех ресурсах, которыми он управляет, нужно занести информацию о существующем правиле.

   Команда позволяет добавить информацию о созданном без помощи Terraform ресурсе в state файл. В директории terraform выполните команду: import

   ```bash
   $ terraform import google_compute_firewall.firewall_ssh default-allow-ssh
   google_compute_firewall.firewall_ssh: Importing from ID "default-allow-ssh"...
   google_compute_firewall.firewall_ssh: Import complete!
   Imported google_compute_firewall (ID: default-allow-ssh)
   google_compute_firewall.firewall_ssh: Refreshing state... (ID: default-allow-ssh)
   Import successful!
   ```

#### Зависимости

- Неявная зависимостьСсылку в одном ресурсе на атрибуты другого тераформ понимает как зависимость одного ресурса от другого. Это влияет на очередность создания и удаления ресурсов при применении изменений.
- Можно явно указать зависимости через аргумент depends_on
  https://www.terraform.io/docs/configuration/resources.html#depends_on-explicit-resource-dependencies

#### Модули

Позволяют разбить конфигурационный файл инфраструктура на составляющие. Их легче конфигурировать проще отлаживать и можно переиспользовать.

Чтобы начать использовать модули, нам нужно сначала их загрузить из указанного источника

```bash
$ terraform get
```

В сентябре 2017 компания HashiCorp запустила [публичный реестр модулей для terraform](https://registry.terraform.io/). До этого модули можно было либо хранить либо локально, как мы делаем в этом ДЗ, либо забирать из Git, Mercurial или HTTP. На главной странице можно искать необходимые модули по названию и фильтровать по провайдеру. Например, [ссылка](https://registry.terraform.io/browse/modules?provider=google) модулей для провайдера google. Модули бывают Verified и обычные. Verified это модули от HashiCorp и ее партнеров

Правильно все переенные передавать в модуль вместе с вызовом этого модуля, поэтому в модуле обычно нету файла ***.tfvars**

#### Шаблоны

Пример применения: положить на удаленную машину конфиг и заполнить в нем зачения переменных. Предпочтительный вариант использовать 

```yaml
content = templatefile("путь до файла/hosts.tpl", {
  names = local.names,
  addrs = local.ips,
  user = var.user
})
* - Путь до файла можно задать через переменную
```

https://alexharv074.github.io/2019/11/23/adventures-in-the-terraform-dsl-part-x-templates.html#template-providers--21



# Packer

Packer — это инструмент для создания одинаковых образов ОС для различных платформ из одного описания.

Достаточно давно [Патрик Дебоиз](http://www.jedi.be/blog/) (это человек, который придумал термин DevOps) написал [Veewee](https://github.com/jedi4ever/veewee) — инструмент, который позволяет автоматически создавать образа для VirtualBox, KVM и VMWare.

Packer пошел дальше, и позволяет делать то же самое для распространенных облачных провайдеров: [Amazon](http://www.packer.io/docs/builders/amazon.html),[DigitalOcean](http://www.packer.io/docs/builders/digitalocean.html), [OpenStack](http://www.packer.io/docs/builders/openstack.html) и [GCE](http://www.packer.io/docs/builders/googlecompute.html). Также Packer позволяет создавать контейнеры для [Docker](https://www.docker.io/).

Взято отсюда: https://habr.com/ru/company/express42/blog/212085/

#### Установка и натройка

Инструкция поустановке https://packer.io/downloads.html

Распакуйте скачанный zip архив и поместите бинарный файл в директорию, путь до которой содержится в переменной окружения PATH.

```bash
$ packer -v
```

Для управления ресурсами GCP через сторонние приложения, такие как Packer и Terraform, нам нужно предоставить этим инструментам информацию (credentials) для аутентификации и управления ресурсами GCP нашего акаунта.

Application Default Credentials (ADC)

Установка ADC позволяет приложениям, работающим с GCP ресурсами и использующим Google API библиотеки, управлять ресурсами GCP через авторизованные API вызовы, используя credentials вашего пользователя.

Создайте АDC:

```bash
$ gcloud auth application-default login
```

#### Пример шаблона

Шаблоны хранятся в формате .json.

Если **builders** секция отвечает за создание виртуальной машины для билда и создание машинного образа в GCP, то секция **provisioners** позволяет устанавливать нужное ПО, производить настройки системы и конфигурацию приложений на созданной VM.

Вот примера шаблона:

```json
{
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "infra-189607",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "source_image_family": "ubuntu-1604-lts",
            "zone": "us-central1-f",
            "ssh_username": "appuser",
            "machine_type": "f1-micro"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

- type: "googlecompute" - что будет создавать виртуальную машину для билда образа (в нашем случае Google Compute Engine)

- project_id: "infra-00001" - id вашего проекта

- image_family: "reddit-base" - семейство образов к которому будет принадлежать новый образ

- image_name: "reddit-base-{{timestamp}}" - имя создаваемого образа
- source_image_family: "ubuntu-1604-lts" - что взять за базовый образ для нашего билда

- zone: "europe-west1-b" - зона, в которой запускать VM для билда образа
- ssh_username: "appuser" - временный пользователь, который будет создан для подключения к VM во время билда и выполнения команд провижинера (о нем поговорим ниже)
- machine_type: "f1-micro" - тип инстанса, который запускается для билда
- Используем [shell provisioner](https://packer.io/docs/provisioners/shell.html), который позволяет запускать bash команды на запущенном инстансе.
- Опция execute_command позволяет указать, каким способом будет запускаться скрипт. Т.к. команды по установке требуют sudo, то мы указываем, что запускать скрипт следует с sudo

```bash
# проверить на наличие ошибок
$ packer validate  -var-file variables.json ./ubuntu16.json
# запустить сборку образа
$ packer build -var-file variables.json ubuntu16.json
```

#### Параметризация параметров

Файл **variables.json** нужно добавлять в gitignore а для примера создавать файл **variables.json.example** c вымышленными заначениями

Значения параметров хранятся в файле **variables.json**

```json
{
  "project_id": "infra-00001",
  "source_image_family": "ubuntu-1604-lts",
  "machine_type": "f1-micro"
}
```

А сами значения параметров в файле меняются на 

```json
{
"project_id": "{{user `project_id`}}",
"source_image_family": "{{user `source_image_family`}}",
"machine_type": "{{user `machine_type`}}"
}
```

Готовый образ можно использовать для быстрого развертывания VM



# Google Cloud Platform

Облачная платформа от google

Для теста потребуется учетка и пластиковая карта (виртуальные вроде не подходят)
Также у меня не сработало с только что созданными учетками.

https://console.cloud.google.com/

#### Установака gcloud

https://cloud.google.com/sdk/docs/

Я установил в каталог **/opt/google-cloud-sdk/** якобы тут должны лежать программы пользователя установленные не из репозитрия

Также нужно обновить пути:

```bash
# The next line updates PATH for the Google Cloud SDK.
$ source '[path-to-my-home]/google-cloud-sdk/path.bash.inc'
# The next line enables bash completion for gcloud.
$ source '[path-to-my-home]/google-cloud-sdk/completion.bash.inc'
```

#### Команды

```bash
gcloud auth list
gcloud info
gcloud inint
# создать витруальную машину
gcloud compute instances create instance-from-gcloud-cli \
  --boot-disk-size=10GB \
  --image=ubuntu-1604-xenial-v20170815a \
  --image-project=ubuntu-os-cloud \
  --machine-type=f1-micro \
  --labels=role=willberemovedin24h \
  --preemptible \
  --restart-on-failure \
  --zone=europe-west1-d
# появится два предупреждения, одно про меделенную работу дисков размером меньше 200 ГБ, второе про то что старые образ будет заменен на более свежий

#Можно вместо --image указывать --image-family, что дает большую свободу (не нужно искать какой образ последний)
  --image-family ubuntu-1604-lts \
# пример списка хостов
gcloud compute instances list
# чтобы указать startup script нужно добавить опцию
  --metadata-from-file startup-script=path/to/file
# так можно загрузить startup script из интернета
  --metadata startup-script-url=gs://bucket/startupscript.sh
# удалить инстанс
gcloud compute instances delete INSTANCE_NAMES
# рыба
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=f1-micro \
  --zone=us-central1-f \
  --tags=puma-server,http-server \
  --restart-on-failure \
  --boot-disk-type=pd-standard \
  --metadata-from-file startup-script=path/to/file
```

#### Bucket

Хранилище до 5ТБ, которое доступно из любого проекта. Подходит для организации данных

```bash
# Создаем бакет(емкость для данных), имя должно быть уникальным!!!
gsutil mb gs://otus-test

# Смотрим что есть
gsutil ls               

# Копируем файл в Storage
gsutil cp Storage-test.txt gs://otus-test/

# Смотрим содержимое
gsutil cat gs://otus-test/Storage-test.txt

# Копируем к себе файл
gsutil cp gs://otus-test/Storage-test.txt local.Storage-test.txt
```

#### Firewall

```bash
# создать правило ис комадоной строки
gcloud compute firewall-rules create default-puma-server1  --allow=tcp:9292   --source-ranges=0.0.0.0/0   --target-tags=puma-server
```

#### Сервисный аккаунт

https://cloud.google.com/iam/docs/creating-managing-service-accounts - как создавать сервисный аккаунт (может потребоваться например для  terraform)

https://cloud.google.com/iam/docs/creating-managing-service-account-keys - как сгенерировать ключи для сервисного аккаунта



# SSH

Сгенегрировать ключ для пользователя appuser с пустым паролем

```bash
$ ssh-keygen -t rsa -f ~/.ssh/appuser -C appuser -P ""
$ ssh -i ~/.ssh/appuser appuser@<внешний IP VM> - подключиться к внешней VM -i указать серт
$ ssh-add -L - перечисляет параметры публичных ключей всех идентификаторов, представленных агентом в настоящий момент
$ ssh-add ~/.ssh/appuser - Добавить приватный ключ в агент авторизации
$ ssh -i ~/.ssh/appuser -A appuser@<внешний IP VM> - -A принудительно использовать SSH Agent Forwarding (посмотреть как настроить в конфиге)
```

#### Настройка подключения в одну комманду:
```bash
$ alias someinternalhost="ssh -i ~/.ssh/appuser -A -J appuser@<ext. IP> appuser@<int. IP>"
```

# Travis CI

Все настройки travis хранаятся в файле .travis.yml в корне репозитория. Для успешной интеграции его со sklack потребуется

1. https://slack.com/intl/en-ru/help/articles/232289568-GitHub-for-Slack
2. /github subscribe Otus-DevOps-2020-02/<GITHUB_USER>_infra commits:all
3. В slack разрешить отправку сообщений о статусе билда

#### Хранение секретов

Секрет хранится в зашифрованном виде в файле .travis.yml. Для создания секрета для интеграции slack и travis:

```bash
$ gem install travis
$ travis <login> --com
$ travis encrypt "devops-team-otus:<ваш_токен>#<имя_вашего_канала>" \ --add notifications.slack.rooms --com
```

#### Литература (Дополнить)



# Шпаргалка git

#### Первым делом

Перед началом работы  с репозиторием нужно минимум задать имя пользователя и почту, [подробнее тут](https://git-scm.com/book/ru/v2/Введение-Первоначальная-настройка-Git). Задается ключиком либо для локально для репозитория --local, либо для текущего пользователя --global, либо для сисемы целиком --system.

```bash
$ git config --global user.name "John Doe"
$ git config --global user.email johndoe@example.com
```

Все эти настройки лежат в файле  .gitconfig (либо в репозитории, либо в домашней папке ~). Еще можно добавить алиасы, они экономят время

```ini
$ cat ~/.gitconfig
[user]
  name = John Doe
email = johndoe@example.com
[color]
  ui = auto
[alias]
  ci = commit
  co = checkout
  st = status
```

Чтобы посмотреть все установленные настройки и узнать где именно они заданы, используйте команду, находясь внутри репозитория:

```bash
$ git config --list --show-origin
```

#### Cоздать репозиторий

```bash
$ git init          - cоздать репозиторий
$ git clone <url>   - cклонировать репозиторий
```

#### История

```bash
$ git log                   - история коммитов
$ git show                  - информация о последнем коммите
$ git show <hash>           - информация об определенном коммите
$ git diff                  - непроиндексипрованный изменения
$ git diff --cached         - проиндексированные изменения

$ git log --all             - коммиты всех веток
$ git log -p                - показывает дельту изменений
$ git log --graph --all     - рисует граф ветвлений
$ git log --oneline	        - выводит коммиты в одну строчку
$ git blame                 - показывает, какие коммиты меняли строки файла
$ git remote -v             - посмотреть информацию об онлайн репозиториях
```

#### Добаить файлы в stage фазу

```bash
$ git add	<name>  - добавить файл в отслеживаемые
$ git add .       - добавить все файлы в отслеживаемые
```

#### Коммит

```bash
$ git commit -am "Comment"  - с ключом -а индексируются все измененный и удаленные файлы. Ключ -m позволяет сразу задать комментаррий
$ git commit --amend        - позволяет изменить последний коммит (предварительно нужно добавить изменения в stage)
```

#### Безопасная отмена изменений определенного коммита

Создается еще один коммит в котором происходит отмена.

```bash
$ git revert <hash>     - отмена определенного коммита (обычно на этом месте возникает кофликт)
$ git status            - посмотреть, где произошел конфликт
$ git show <hash>       - посмотреть, что требуется удалить
# затем нужно вручную удалить лишнее и маркеры
$ git add <name>        - добавить файл в stage
$ git revert --continue - продолжить процесс отмены коммита
```

####  Ветки

```bash
$ git branch                - посмотреть текущее состояние веток
$ git branch <name>         - создать ветку
$ git checkout -b <name>    - создать ветку и перейти внее
$ git merge <name>          - слить ветку <name> с текущей в которой находимся
```

#### .gitignore

Позволяет явно объявить какие имена файлов не нужно отслеживать. Можно использовать маски.

#### .git/hooks

Git позволяет выполнять определённые сценарии, когда происходят важные действия. Сценарии git находятся в каталоге .git/hooks.

Перехватчики могут быть:

- На стороне клиента

  - pre-commit https://pre-commit.com/

    ```bash
    $ pip install pre-commit	-  установит автоматический обработчик
    # затем в папку с проектом нужно добавить конфигурационный файл .pre-commit-config.yaml
    $ pre-commit install
    ```

  - pre-push

  - др.

- На стороне сервера

  - pre-receive
  - post-receive
  - др.

Создание git hooks

- Должны находиться строго в директории .git/hooks
- Момент запуска того или иного скрипта определяется по его имени
- Могут быть написаны с использованием любого скриптового языка. Например: bash, python и др.
- Выполнение git hooks не считается успешным, если он завершается с любым кодом не равным 0

https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks

#### Rebase  (дополнить)

Пока мы не опубликовали наши изменения, можно "переписывать историю" с помощью rebase, например так:

```
$ git rebase -i HEAD~4
```

#### Полезные дополнения

```bash
 $ git log --grep=XXX #позволяет выполнять поиск по сообщениям в коммитах
 $ git log --graph --abbrev-commit --decorate --all --oneline  #наглядно показать историю
 $ git branch -vv -a #показывает все ветки, включая на удаленном сервере
 $ git checkout -b serverfix remotes/origin/gitlab-ci-1 #создает новую ветку serverfix наследуясь от ветки с удаленного сервера gitlab-ci-1
```

#### Инструменты

https://www.sourcetreeapp.com/

#### Литература

https://learngitbranching.js.org/

http://zzet.org/git/learning/undev/coursify/2014/02/09/lection-1-git-course-undev.html

https://git-scm.com/book/ru/v2
