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