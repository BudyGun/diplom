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