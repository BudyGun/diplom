# Описание Elasticsearch VM

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
      image_id = "fd8l45jhe4nvt0ih7h2e"
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
    user-data = "${file("/home/vboxuser/diplom/meta.yaml")}"
}

  scheduling_policy {
    preemptible = true
  }

}