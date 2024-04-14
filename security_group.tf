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