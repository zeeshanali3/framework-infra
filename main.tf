resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "framework-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = var.container_env_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}


################################ MySQL Server Resource ######################

resource "azurerm_mysql_flexible_server" "mysql" {
  name                = var.mysql_server_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login    = var.mysql_admin_user
  administrator_password = var.mysql_admin_password

  sku_name = "GP_Standard_D2ds_v4" # 
  version  = "8.0.21"

  storage {
    size_gb = 32
  }

  backup_retention_days = 7
  #zone                  = "1" #facing issue when specifying the zone

  depends_on = [
    azurerm_resource_group.rg
  ]
}

# resource "azurerm_mysql_flexible_database" "user_db" {
#   name                = "db_${var.user_id}"
#   resource_group_name = azurerm_resource_group.rg.name
#   server_name         = azurerm_mysql_flexible_server.mysql.name
#   charset             = "utf8"
#   collation           = "utf8_general_ci"
# }

###################### Networking (ALLOW ACCESS FOR NOW) ######################

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

###################### backend Container ######################


resource "azurerm_container_app" "backend" {
  name                         = "backend-${var.user_id}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    # Allows scaling to zero when no traffic is detected
    min_replicas = 0 
    max_replicas = 5

    # 1. THE SAFE: Define all secrets from your JSON map
    dynamic "secret" {
      for_each = local.secret_map
      content {
        name  = lower(replace(MY_APP_SECRETS, "_", "-"))
        value = secret.value
      }
    }

    container {
      name   = "api"
      image  = "${azurerm_container_registry.acr.login_server}/backend:${var.user_id}"
      cpu    = 0.5
      memory = "1Gi"

      # Static env variable
      env {
        name  = "PROJECT_ID"
        value = var.user_id
      }

      # 2. THE KEY: Dynamically map all JSON secrets to env vars
      dynamic "env" {
        for_each = local.secret_map
        content {
          name        = env.key
          secret_name = lower(replace(MY_APP_SECRETS, "_", "-"))
        }
      }
    }

    # Scaling rule to trigger wake-up from zero
    http_scale_rule {
      name                = "http-scale"
      concurrent_requests = "10"
    }
  }

  ingress {
    external_enabled = true # Set to true if frontend needs to reach it via URL
    target_port      = 8080 # Matches SERVER_PORT in your JSON
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
