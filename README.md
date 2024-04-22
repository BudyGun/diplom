#  Дипломная работа по профессии «Системный администратор» Чумаков Константин SYS-25

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)



# РЕШЕНИЕ   

## Конфигурационные файлы terraform  
[bastion.tf](https://github.com/BudyGun/diplom/blob/main/terraform/bastion.tf) - конфиг машины bastion.       
[elasticsearch.tf](https://github.com/BudyGun/diplom/blob/main/terraform/elasticsearch.tf) - конфиг машины elasticsearch.      
[zabbix.tf](https://github.com/BudyGun/diplom/blob/main/terraform/zabbix.tf) - конфиг машины zabbix.    
[kibana.tf](https://github.com/BudyGun/diplom/blob/main/terraform/kibana.tf) - конфиг машины kibana.      
[webserver-1.tf](https://github.com/BudyGun/diplom/blob/main/terraform/webserver-1.tf) - конфиг машины webserver-1.  
[webserver-2.tf](https://github.com/BudyGun/diplom/blob/main/terraform/webserver-2.tf) - конфиг машины webserver-2.   
[main.tf](https://github.com/BudyGun/diplom/blob/main/terraform/main.tf) - конфиг terraform.    
[meta.yaml](https://github.com/BudyGun/diplom/blob/main/terraform/meta.yaml) - метаданные.   
[networks.tf](https://github.com/BudyGun/diplom/blob/main/terraform/networks.tf) - конфиг сетей.   
[outputs.tf](https://github.com/BudyGun/diplom/blob/main/terraform/outputs.tf) - конфиг вывода инфо по адресам.  
[security_group.tf](https://github.com/BudyGun/diplom/blob/main/terraform/security_group.tf) - конфиг групп безопасности.    
[alb.tf](https://github.com/BudyGun/diplom/blob/main/terraform/alb.tf) - конфиг таргет групп, роутера, балансировщика.   
[snapshot.tf](https://github.com/BudyGun/diplom/blob/main/terraform/snapshot.tf) - конфиг снапшотота.   

## Конфигурационные файлы ansible
[ansible](https://github.com/BudyGun/diplom/blob/main/ansible/) - конфиги ansible, таски, хандлеры, инвентори...

## Конфигурационные файлы сайта
[index1.html](https://github.com/BudyGun/diplom/blob/main/ansible/www/index1.html) - вэб-страница 1    
[index2.html](https://github.com/BudyGun/diplom/blob/main/ansible/www/index2.html) - вэб-страница 2    
[nginx.yaml](https://github.com/BudyGun/diplom/blob/main/ansible/nginx.yaml) - плэйбук установки нджинкса и заканчивания вэб-страниц на сервера   

## Конфигурационные файлы zabbix
[all.yml](https://github.com/BudyGun/diplom/blob/main/ansible/all.yml) - плэйбукс создания заббикс-сервера   
[agen_z.yml](https://github.com/BudyGun/diplom/blob/main/ansible/agent_z.yml) - плэйбукс создания заббикс-агентов

## Установка terraform.
Скачиваю архив терраформ с яндекс-облака:
```
wget https://hashicorp-releases.yandexcloud.net/terraform/1.6.1/terraform_1.6.1_linux_amd64.zip
```
Распаковываю скачанный архив:
```
unzip terraform_1.6.1_linux_amd64.zip
```
Чтобы терраформ был доступен для запуска из командной строки из любого места копирую его в системную папку:
```
sudo cp terraform /usr/local/bin/
```
Проверяю
```
terraform -v
```
![alt text](https://github.com/BudyGun/diplom/blob/main/images/ter1.png)    

Создаю файл конфигурации .terraformrc в домашнем каталоге:   
```
nano ~/.terraformrc
```
С содержимым:   
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```
В папке, где буду запускать терраформ создаю файл main.tf:
```
nano main.tf
```
С содержимым:
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

# Описание доступа и токена
provider "yandex" {
  service_account_key_file= "/home/vboxuser/.ssh/authorized_key.json"
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone = "ru-central1-a"
}
```
В папке, где буду запускать терраформ создаю файл переменных variables.tf:
```
nano variables.tf
```
С содержимым, где описаны переменные, следующего вида:
```
variable "cloud_id" {
default = "b1guu8d****"
}

variable "folder_id" {
default = "b1gom66****"
}

```
Генерирую пару ssh-ключей.   
```
ssh-keygen -t ed25519
```
Публичный ключ копирую и вставляю в файл meta.yaml, указав в нём же данные по пользователю. Файл кладу в ту же папку, где буду запусакть терраформ. Содержимое файла:
```
#cloud-config
users:
  - name: user
    groups: sudo
    shell: /bin/bash
    sudo: 'ALL=(ALL) NOPASSWD:ALL'
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI********** vboxuser@ubuntu-diplom
```
Путь до это файла будет прописан в файлах создаваемых машин:
```
 metadata = {
    user-data = "${file("./meta.yaml")}"
}
```
Создаю конфиг машины Bastion (файл bastion.tf). Использую образ операционной системы Ubuntu 22.04 LTS   
Идентификаторы продукта:   
image_id: fd8s4upujl9u40j5p77l   

```
nano bastion.tf
```

```
# Bastion
resource "yandex_compute_instance" "bastion" {

  name     = "bastion"
  hostname = "bastion"
  zone     = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4upujl9u40j5p77l"
      size     = 12
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-external-segment.id

    security_group_ids = [
                          yandex_vpc_security_group.external-ssh-sg.id,
                          yandex_vpc_security_group.internal-ssh-sg.id,
                          yandex_vpc_security_group.zabbix-sg.id,
                          yandex_vpc_security_group.egress-sg.id
                         ]

    nat        = true
    ip_address = "192.168.50.10"
  }

 metadata = {
    user-data = "${file("./meta.yaml")}"
}

  scheduling_policy {
    preemptible = true
  }

}
```
Создаю конфиг машины Kibana (файл kibana.tf). Использую образ операционной системы Ubuntu 22.04 LTS   
Идентификаторы продукта:   
image_id: fd8s4upujl9u40j5p77l   

```
nano kibana.tf
```
```
# Kibana
resource "yandex_compute_instance" "kibana" {

  name                      = "kibana"
  hostname                  = "kibana"
  zone                      = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4upujl9u40j5p77l"
      size     = 12
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-external-segment.id

    security_group_ids = [
                           yandex_vpc_security_group.internal-ssh-sg.id,
                           yandex_vpc_security_group.external-ssh-sg.id,
                           yandex_vpc_security_group.zabbix-sg.id,
                           yandex_vpc_security_group.kibana-sg.id,
                           yandex_vpc_security_group.egress-sg.id
                         ]

    nat        = true
    ip_address = "192.168.50.30"
  }

metadata = {
    user-data = "${file("./meta.yaml")}"
}

  scheduling_policy {
    preemptible = true
  }

}
```
Создаю конфиг машины elasticsearch (файл elasticsearch.tf). Использую образ операционной системы Ubuntu 22.04 LTS   
Идентификаторы продукта:   
image_id: fd8s4upujl9u40j5p77l  

```
nano elasticsearch.tf
```

```
# Elasticsearch

resource "yandex_compute_instance" "elasticsearch" {

  name = "elasticsearch"
  hostname = "elasticsearch"
  zone = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4upujl9u40j5p77l"
      size     = 12
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-internal-segment.id

    security_group_ids = [
                           yandex_vpc_security_group.internal-ssh-sg.id,
                           yandex_vpc_security_group.external-ssh-sg.id,
                           yandex_vpc_security_group.zabbix-sg.id,
                           yandex_vpc_security_group.elastic-sg.id,
                           yandex_vpc_security_group.egress-sg.id
                         ]
    nat       = false
    ip_address = "192.168.10.30"
  }

 metadata = {
    user-data = "${file("./meta.yaml")}"
}

  scheduling_policy {
    preemptible = true
  }

}
```
Создаю конфиги машин webserver-1 и 2 (файл webservers.tf). Использую образ операционной системы Ubuntu 22.04 LTS   
Идентификаторы продукта:   
image_id: fd8s4upujl9u40j5p77l  
```
nano webservers.tf
```
```
# web server 1

resource "yandex_compute_instance" "webserver-1" {
  name = "webserver-1"
  hostname = "webserver-1"
  zone = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4upujl9u40j5p77l"
      size     = 12
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-internal-segment.id
    security_group_ids = [
                           yandex_vpc_security_group.internal-ssh-sg.id,
                           yandex_vpc_security_group.alb-vm-sg.id,
                           yandex_vpc_security_group.zabbix-sg.id,
                           yandex_vpc_security_group.egress-sg.id
                         ]
/*    security_group_ids = [
                            yandex_vpc_security_group.external-ssh-sg.id,
                            yandex_vpc_security_group.internal-ssh-sg.id
                           ] */

    nat       = false
    ip_address = "192.168.10.10"
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }

}


# web server 2 

resource "yandex_compute_instance" "webserver-2" {
  name = "webserver-2"
  hostname = "webserver-2"
  zone = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4upujl9u40j5p77l"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-internal-segment.id
    security_group_ids = [
                           yandex_vpc_security_group.internal-ssh-sg.id,
                           yandex_vpc_security_group.alb-vm-sg.id,
                           yandex_vpc_security_group.zabbix-sg.id,
                           yandex_vpc_security_group.egress-sg.id
                         ]

/*    security_group_ids = [
                            yandex_vpc_security_group.external-ssh-sg.id,
                            yandex_vpc_security_group.internal-ssh-sg.id
                           ] */
    nat       = false
    ip_address = "192.168.10.20"
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

    scheduling_policy {
    preemptible = true
  }
}
```
Создаю конфиг машины zabbix (zabbix.tf). Использую образ операционной системы Ubuntu 22.04 LTS   
Идентификаторы продукта:   
image_id: fd8s4upujl9u40j5p77l  
```
nano zabbix.tf
```

```
# Zabbix

resource "yandex_compute_instance" "zabbix-server" {

  name                      = "zabbix-server"
  hostname                  = "zabbix-server"
  zone                      = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4upujl9u40j5p77l" 
      size     = 12
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-external-segment.id

    security_group_ids = [
                           yandex_vpc_security_group.internal-ssh-sg.id,
                           yandex_vpc_security_group.external-ssh-sg.id,
                           yandex_vpc_security_group.zabbix-server-sg.id,
                           yandex_vpc_security_group.egress-sg.id
                         ]

    nat        = true
    ip_address = "192.168.50.20"
  }

metadata = {
    user-data = "${file("./meta.yaml")}"
}

  scheduling_policy {
    preemptible = true
  }

}
```


Создаю файл групп безопасности ( файл security_group.tf):
```
nano security_group.tf
```
```
# Внешний ssh/External ssh

resource "yandex_vpc_security_group" "external-ssh-sg" {
  name                = "external-ssh-sg"
  description         = "Внешний ssh//external ssh"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    description       = "Входящий трафик TCP. с любого адреса на порт 22"
    protocol          = "TCP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 22
  }

  ingress {
    description       = "Входящий трафик TCP. из локального SSH (internal-ssh-sg) на  порт 22"
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.internal-ssh-sg.id
    port              = 22
  }

  egress {
    description       = "Исходящий трафик любой. На любой адрес. На любой порт"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }

  egress {
    description       = "Исходящий трафик TCP на порт 22 на локальный SSH (internal-ssh-sg)"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.internal-ssh-sg.id
  }

}

# Внутренний локальный ssh/Internal ssh

resource "yandex_vpc_security_group" "internal-ssh-sg" {

  name                = "internal-ssh-sg"
  description         = "Внутренний локальный ssh/Internal ssh"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    description       = "Входящий трафик TCP на порт 22"
    protocol          = "TCP"
    v4_cidr_blocks    = ["192.168.10.0/24"]
    port              = 22
  }

  egress {
    description       = "Исходящий трафик TCP на порт 22"
    v4_cidr_blocks    = ["192.168.10.0/24"]
    protocol          = "TCP"
    port              = 22
  }

  egress {
    description       = "Исходящий трафик только tcp на порт 22"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }

}

# На Балансировщик входящий трафик

resource "yandex_vpc_security_group" "alb-sg" {
  name                = "alb-sg"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 80
  }

  ingress {
    description       = "healthchecks"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
}

# От балансировщика на Web-servers

resource "yandex_vpc_security_group" "alb-vm-sg" {
  name                = "alb-vm-sg"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.alb-sg.id
    port              = 80
  }

  ingress {
    description       = "ssh"
    protocol          = "TCP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 22
  }

}

# Разрешает весь исходящий трафик

resource "yandex_vpc_security_group" "egress-sg" {
  name                = "egress-sg"
  network_id          = yandex_vpc_network.bastion-network.id

  egress {
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}

# Zabbix agent security group

resource "yandex_vpc_security_group" "zabbix-sg" {
  name                = "zabbix-sg"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.zabbix-server-sg.id
    from_port         = 10050
    to_port           = 10051
  }

  egress {
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.zabbix-server-sg.id
    from_port         = 10050
    to_port           = 10051
  }
}

# Zabbix server security group

resource "yandex_vpc_security_group" "zabbix-server-sg" {
  name        = "zabbix-server-sg"
  network_id  = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks    = yandex_vpc_subnet.bastion-external-segment.v4_cidr_blocks
    from_port         = 10050
    to_port           = 10052
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks    = yandex_vpc_subnet.bastion-internal-segment.v4_cidr_blocks
    from_port         = 10050
    to_port           = 10051
  }

}

#Elasticsearch server security group

resource "yandex_vpc_security_group" "elastic-sg" {
  name        = "elastic-sg"
  network_id  = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = yandex_vpc_subnet.bastion-internal-segment.v4_cidr_blocks
    port = 9200
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = yandex_vpc_subnet.bastion-external-segment.v4_cidr_blocks
    port = 9200
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = yandex_vpc_subnet.bastion-internal-segment.v4_cidr_blocks
    port = 9300
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = yandex_vpc_subnet.bastion-external-segment.v4_cidr_blocks
    port = 9300
  }

}

#Kibana server security group

resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  network_id  = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 5601
  }

}
```
Создаю файл конфига сетей ( файлл networks.tf )
```
nano networks.tf
```
```
# Сети и подсети

# External Network

resource "yandex_vpc_network" "bastion-network" {
  name = "bastion-network"
}

# Подсеть №1. Внешняя
# Subnet #1. External

resource "yandex_vpc_subnet" "bastion-external-segment" {
  name           = "bastion-external-segment"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.bastion-network.id
  v4_cidr_blocks = ["192.168.50.0/24"]
}

# Подсеть №2. Внутренняя
# Subnet #2. Internal

resource "yandex_vpc_subnet" "bastion-internal-segment" {
  name           = "bastion-internal-segment"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.bastion-network.id
  v4_cidr_blocks = ["192.168.10.0/27"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "rt"
  network_id = yandex_vpc_network.bastion-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
```
файл конфига outputs.tf вывода в консоль информации:
```
nano outputs.tf
```
```
# Bastion-host
output "bastion_nat" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}
output "bastion" {
  value = yandex_compute_instance.bastion.network_interface.0.ip_address
}

# Вэбсервер - 1
output "webserver-1" {
  value = yandex_compute_instance.webserver-1.network_interface.0.ip_address
}

# Вэбсервер - 2
output "webserver-2" {
  value = yandex_compute_instance.webserver-2.network_interface.0.ip_address
}

# kibana-сервер
output "kibana-nat" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}
output "kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.ip_address
}

# zabbix-сервер
output "zabbix_nat" {
  value = yandex_compute_instance.zabbix-server.network_interface.0.nat_ip_address
}
output "zabbix" {
  value = yandex_compute_instance.zabbix-server.network_interface.0.ip_address
}

# elasticsearch-сервер
output "elasticsearch" {
  value = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
}

# Балансировщик
output "load_balancer_pub" {
  value = yandex_alb_load_balancer.alb-lb.listener[0].endpoint[0].address[0].external_ipv4_address
}
```
Создание таргет и целевой группы ( файл alb.tf):
```
nano alb.tf
```
```
#Таргет группа/Целевая группа

resource "yandex_alb_target_group" "tg-web" {
  name = "tg-web"

  target {
    subnet_id  = yandex_vpc_subnet.bastion-internal-segment.id
    ip_address = yandex_compute_instance.webserver-1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.bastion-internal-segment.id
    ip_address = yandex_compute_instance.webserver-2.network_interface.0.ip_address
  }
}

#Группа бэкэндов

resource "yandex_alb_backend_group" "alb-bg" {
  http_backend {
    name             = "alb-bg-1"
    target_group_ids = ["${yandex_alb_target_group.tg-web.id}"]
    port             = 80
    healthcheck {
      timeout  = "10s"
      interval = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP-роутер для HTTP-трафика

resource "yandex_alb_http_router" "web-servers-router" {
  name = "web-servers-router"
}

resource "yandex_alb_virtual_host" "alb-host" {
  name           = "alb-host"
  http_router_id = yandex_alb_http_router.web-servers-router.id
  route {
    name = "my-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.alb-bg.id
        timeout           = "60s"
      }
    }
  }
}

#L7-балансировщик

resource "yandex_alb_load_balancer" "alb-lb" {
  name       = "alb-lb"

  network_id = yandex_vpc_network.bastion-network.id

  security_group_ids = [ yandex_vpc_security_group.alb-sg.id,
                         yandex_vpc_security_group.egress-sg.id,
                         yandex_vpc_security_group.alb-vm-sg.id,
                         yandex_vpc_security_group.external-ssh-sg.id,
                         yandex_vpc_security_group.internal-ssh-sg.id
                       ]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.bastion-external-segment.id  
    }
  }


  listener { /* описание параметров обработчика для L7-балансировщика */
    name = "alb-listener"

    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.web-servers-router.id /* <идентификатор_HTTP-роутера> */
      }
    }
  }
}
```
Создаю снапшот:
```
nano snapshot.tf
```
```
resource "yandex_compute_snapshot_schedule" "snapshot" {
  name = "snapshot"

  schedule_policy {
    expression = "0 15 ? * *"
  }

  retention_period = "168h"

  snapshot_count = 7

  snapshot_spec {
    description = "daily-snapshot"
  }

  disk_ids = [
    "${yandex_compute_instance.bastion.boot_disk.0.disk_id}",
    "${yandex_compute_instance.webserver-1.boot_disk.0.disk_id}",
    "${yandex_compute_instance.webserver-1.boot_disk.0.disk_id}",
    "${yandex_compute_instance.zabbix-server.boot_disk.0.disk_id}",
    "${yandex_compute_instance.elasticsearch.boot_disk.0.disk_id}",
    "${yandex_compute_instance.kibana.boot_disk.0.disk_id}", ]
}
```
Запускаю терраформ и проверяю поднятие инфраструктуры в облаке:
```
terraform init
```
```
terraform apply
```
Инфраструктура поднята:   
![alt text](https://github.com/BudyGun/diplom/blob/main/images/infrastr.png)    

Проверяю доступность машины bastion по ssh:
```
ssh user@51.250.89.119
```
Машина доступна:    
![alt text](https://github.com/BudyGun/diplom/blob/main/images/infrastr2.png)   

Поднята облачная инфраструктура: вм, сети и подсети, балансировщик, группы безопасности: 
![alt text](https://github.com/BudyGun/diplom/blob/main/images/common.png) 
![alt text](https://github.com/BudyGun/diplom/blob/main/images/vm-1.png) 
![alt text](https://github.com/BudyGun/diplom/blob/main/images/sg.png) 



## Ansible   
Устанавливаю ansible на машину, где собирается проект:   
```
sudo apt install ansible
```
Создаю папку ansible в проекте и вней создаю файл конфигурации ansible.cfg следующего вида:
```
nano ansible.cfg
```
```
[defaults]
inventory = /home/vboxuser/diplom/ansible/hosts.txt
forks = 5
remote_user = user

host_key_checking = False

[privilege_escalation]
become = True
become_method = sudo
```
где, inventory = /home/vboxuser/diplom/ansible/hosts.txt - файл расположения инвентори,
remote_user = user - пользователь, прописанный в метаданных при создании машин, которым я буду подключаться к виртуальным машинам.
Создаю инвентори файл hosts.txt в папке ansible, адреса машин указываю внутренние fqdn-адреса:
```
[bastion_host]
bastion ansible_host=178.154.222.252 ansible_ssh_user=user

[webservers]
webserver-1 ansible_host=webserver-1.ru-central1.internal
webserver-2 ansible_host=webserver-2.ru-central1.internal

[webserver1]
web1 ansible_host=webserver-1.ru-central1.internal ansible_ssh_user=user

[webserver2]
web2 ansible_host=webserver-2.ru-central1.internal ansible_ssh_user=user


[elasticsearch_host]
elasticsearch ansible_host=elasticsearch.ru-central1.internal

[kibana_host]
kibana ansible_host=kibana.ru-central1.internal

[zabbix_host]
zabbix ansible_host=zabbix-server.ru-central1.internal

[webservers:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@178.154.222.252"'

[elasticsearch_host:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@178.154.222.252"'

[kibana_host:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@178.154.222.252"'

[zabbix_host:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@178.154.222.252"'

[all:vars]
ansible_ssh_user=user
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p user@178.154.222.252"'

```
Проверяю доступность всех хостов командой:
```
ansible all -m ping
```
В результате вижу - все хосты на связи:    
![alt text](https://github.com/BudyGun/diplom/blob/main/images/connect.png)  



## Сайт
Создаю плэйбук nginx.yaml для установки nginx на вэбсервера 1 и 2, и закачиваю туда разные фалйлы index.html, отличающихся фоном и текстовой информацией - откуда была загружена страница, прописываю до них пути в плэйбуке:
```
---
- name: Test Connection to my servres
  hosts: webservers
  become: yes

  tasks:
    - name: update apt packages # Обновление пакетов
      apt:
        force_apt_get: true
        upgrade: dist
        update_cache: yes
      become: true

    - name: Install nginx on all servers # Установка nginx
      apt: 
        name: nginx
        state: latest
        update_cache: yes

- name: copy index.html webserver 1 # Копирование index.html на первый сервер
  hosts: webserver1
  become: yes

  tasks:
    - name: copy index_new.html
      ansible.builtin.copy:
        src: ./www/index1.html
        dest: /var/www/html/index.html
        owner: root
        group: sudo
        mode: "0644"

- name: copy index.html webserver 2 # Копирование index.html на второй сервер
  hosts: webserver2
  become: yes
  
  tasks:
    - name: copy index_new.html
      ansible.builtin.copy:
        src: ./www/index2.html
        dest: /var/www/html/index.html
        owner: root
        group: sudo
        mode: "0644"

    - name: Настройка Nginx для отслеживания изменений index.html
      lineinfile:
        path: /etc/nginx/sites-available/default
        regexp: '^index index.html index.htm index.nginx-debian.html;$'
        line: 'index index.html index.htm index.nginx-debian.html;'
        state: present
      notify: reload nginx

  handlers:
    - name: reload nginx
      systemd:
        name: nginx
        state: reloaded
```
Запускаю плэй:    
![alt text](https://github.com/BudyGun/diplom/blob/main/images/nginx.png)     

Проверяю по внешнему адресу балансировщика, что при каждом запросе к 80-му порту происходит поочередная выдача вэб-страниц с двух серверов, сначало с одного потом с другого при каждом обращении, которые в реале будут идентичными.    
![alt text](https://github.com/BudyGun/diplom/blob/main/images/web1.png)     
![alt text](https://github.com/BudyGun/diplom/blob/main/images/web2.png)     

## Мониторинг   
Мониторинг будет развернут на забикс-сервере. Система мониторинга - заббикс.    
Для создания плэйбука установки заббикс сервера использую официальную документацию забикса - https://www.zabbix.com/download?zabbix=6.0&os_distribution=ubuntu&os_version=22.04&components=server_frontend_agent&db=mysql&ws=apache  . Я выбрал такой набор, т.к. установленные машины -ubuntu 22. Для установки использую сервер баз данных Mariadb. В этом же плейбуке поставлю забикс агента на сам сервер.
Создаю плэйбук [all.yml](https://github.com/BudyGun/diplom/blob/main/ansible/all.yml) с задачами:    
1. установки необходимых пакетов,
2. создания базы данных mariadb,
3. задание пароля пользователя root, т.к. изначально после установки пароль пустой,
4. создание базы данных zabbix  и пользователя zabbix,
5. инициализирование базы данных забикса с загрузкой в неё таблиц необходимых для работы и конфига самого сервера забикс.
После налаживания работы каждой задачи без ошибок - соединяю полученные таски в единый плэйбук:

```
---
- name: Install and configure Zabbix Server
  hosts: zabbix_host
  become: yes
  vars:
    sql_script_path: "/usr/share/zabbix-sql-scripts/mysql/server.sql.gz"  # Путь к SQL скрипту    
  vars_files:
    - vars.yml
  
  tasks:

    - name: Copy Zabbix Server 6.0 deb package to remote host
      ansible.builtin.copy:
        src: /home/vboxuser/distrib/zabbix-release_6.0-4+ubuntu22.04_all.deb
        dest: /tmp/zabbix-release_6.0-4+ubuntu22.04_all.deb
        mode: 0644  # Устанавливаем права на файл

    - name: Install Zabbix Server 6.0 deb package
      ansible.builtin.apt:
        deb: /tmp/zabbix-release_6.0-4+ubuntu22.04_all.deb
        state: present

    - name: Update package lists
      ansible.builtin.apt:
        update_cache: yes

    - name: Install necessary packages
      apt:
        name: "{{ item }}"
        state: present
      with_items:
        - zabbix-server-mysql 
        - zabbix-frontend-php 
        - zabbix-apache-conf 
        - zabbix-sql-scripts 
        - zabbix-agent
        - mariadb-server
        - mariadb-client
      become: yes

################################################################################

    - name: Ensure MariaDB is installed
      apt:
        name: mariadb-server
        state: present

    - name: Start MariaDB service
      service:
        name: mariadb
        state: started
        enabled: yes


    - name: Install required system packages for pip
      apt:
        name: python3-pip
        state: present

    - name: Install PyMySQL
      pip:
        name: pymysql
        executable: pip3



    - name: Set root user password using UNIX socket
      mysql_user:
        login_unix_socket: /var/run/mysqld/mysqld.sock
        user: root
        password: "{{ root_password }}"
        check_implicit_admin: yes
        priv: '*.*:ALL,GRANT'
        host_all: yes
      become: yes

    - name: Ensure the MariaDB server is only accessible from localhost
      lineinfile:
        dest: /etc/mysql/mariadb.conf.d/50-server.cnf
        regexp: '^bind-address'
        line: 'bind-address = 127.0.0.1'
        state: present

    - name: Restart MariaDB to apply changes
      service:
        name: mariadb
        state: restarted

##################################################################################

    - name: Create Zabbix database
      mysql_db:
        login_user: root
        login_password: "{{ root_password }}"
        name: "{{ db_name }}"
        state: present
        encoding: utf8mb4
        collation: utf8mb4_bin

    - name: Create Zabbix user
      mysql_user:
        login_user: root
        login_password: "{{ root_password }}"
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        host: localhost
        state: present

    - name: Grant all privileges to Zabbix user
      mysql_user:
        login_user: root
        login_password: "{{ root_password }}"
        name: "{{ db_user }}"
        host: localhost
        priv: "{{ db_name }}.*:ALL"
        append_privs: yes
        state: present

    - name: Set global variable for function creators
      mysql_variables:
        login_user: root
        login_password: "{{ root_password }}"
        variable: log_bin_trust_function_creators
        value: 1

    - name: Restart MariaDB to apply changes
      service:
        name: mariadb
        state: restarted

###################################################################################

   
    - name: Deploy Zabbix database schema
      shell: zcat {{ sql_script_path }} | mysql --default-character-set=utf8mb4 -u{{ db_user }} -p'{{ db_password }}' {{ db_name }}
      args:
        executable: /bin/bash

###################################################################################

    - name: Обновление строки DBPassword в файле zabbix_server.conf
      ansible.builtin.lineinfile:
        path: /etc/zabbix/zabbix_server.conf
        regexp: '^#?DBPassword='
        line: 'DBPassword={{ db_password }}'
        state: present

    - name: 
      ansible.builtin.copy:
        src: zabbix_server.conf
        dest: /etc/zabbix/zabbix_server.conf
        owner: root
        group: root
        mode: '0600' 

    - name: Перезапуск сервисов Zabbix и Apache2
      ansible.builtin.systemd:
        name: "{{ item }}"
        state: restarted
        enabled: yes
      loop:
        - zabbix-server
        - zabbix-agent
        - apache2
```

Для заливки агентов на сервера сделал плэйбук [agent_z.yml](https://github.com/BudyGun/diplom/blob/main/ansible/agent_z.yml), который устанавливает zabbix-агентов и необходимую конфигурацию.   
```
---
- name: Установка Zabbix агента и настройка его запуска
  hosts: myserv_za
  become: yes  # Повышение прав для выполнения задач

  tasks:
    - name: Скачивание Zabbix release пакета
      ansible.builtin.get_url:
        url: "https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb"
        dest: "/tmp/zabbix-release_6.0-4+ubuntu22.04_all.deb"
        mode: '0644'

    - name: Установка Zabbix release пакета
      ansible.builtin.apt:
        deb: "/tmp/zabbix-release_6.0-4+ubuntu22.04_all.deb"

    - name: Обновление списка пакетов
      ansible.builtin.apt:
        update_cache: yes

    - name: Установка Zabbix агента
      ansible.builtin.apt:
        name: zabbix-agent
        state: present

    - name: Настройка файла конфигурации Zabbix агента
      ansible.builtin.template:
        src: templates/zabbix_agentd.conf.j2
        dest: /etc/zabbix/zabbix_agentd.conf
      notify: restart zabbix-agent

    - name: Перезапуск и включение Zabbix агента в автозагрузку
      ansible.builtin.systemd:
        name: zabbix-agent
        state: restarted
        enabled: yes

  handlers:
    - name: restart zabbix-agent
      ansible.builtin.systemd:
        name: zabbix-agent
        state: restarted
        enabled: yes

```
После работы плэйбуков добавляю хосты на сервер.
![alt text](https://github.com/BudyGun/diplom/blob/main/images/zabbix2.png)  

## Логи  
Устанавливаю на вебсервера файлбит, на хост кибану - установочный пакет кибану, и на эластик - пакет elasticsearch. Создаю таски с заливкой сразу конфигурации сервисов. Захожу по внешнему адресу хоста кибана по порту 5601, в дисковери, вижу индексы файл бита, добавляю их. Итог:   
![alt text](https://github.com/BudyGun/diplom/blob/main/images/logs.png) 
