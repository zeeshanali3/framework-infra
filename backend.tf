terraform {
  backend "azurerm" {
    resource_group_name  = "framework"
    storage_account_name = "gtframeterraformstate"
    container_name       = "terraformstate"
    key                  = "prod.terraform.tfstate" # Name of the state file
  }
}