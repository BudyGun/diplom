# Сеть и подсети

# Обозначаем Сеть
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