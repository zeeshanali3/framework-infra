variable "location" {
  default = "westus2"
}

variable "resource_group_name" {
  default = "framework-rg"
}

variable "acr_name" {
  default = "frameworkacr123"
}

variable "container_env_name" {
  default = "framework-env"
}

############### MY SQL Variables ############

variable "mysql_admin_user" {
  default = "gtuser"
}

variable "mysql_admin_password" {
  description = "password"
  sensitive   = true
}

variable "mysql_server_name" {
  default = "framework-mysql"
}

variable "user_id" {
  description = "User ID for project"
  type        = string
}