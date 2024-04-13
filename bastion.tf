# Бастион хост
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
      image_id = "fd8l45jhe4nvt0ih7h2e"
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
    user-data = "${file("/home/vboxuser/diplom/meta.yaml")}"
}

  scheduling_policy {
    preemptible = true
  }

}