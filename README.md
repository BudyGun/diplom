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

## Конфигурационные файлы   
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
С содержимым, где описаны переменные:
```
variable "cloud_id" {
default = "b1guu8dde76an1n4e8ui"
}

variable "folder_id" {
default = "b1gom662a1nlt3u5u012"
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
