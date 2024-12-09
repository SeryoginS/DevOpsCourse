# Вихідні дані для публічних IP-адрес кожної віртуальної машини

output "public_ip_addresses" {
  description = "Public IP addresses of the virtual machines"
  value       = [for ip in azurerm_public_ip.pip : ip.ip_address]
}