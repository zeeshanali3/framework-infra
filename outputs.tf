output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "container_env_id" {
  value = azurerm_container_app_environment.env.id
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

################# MY SQL ####################

output "mysql_host" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_admin_user" {
  value = var.mysql_admin_user
}