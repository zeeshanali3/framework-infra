locals {
  # If you are passing a JSON string from a variable
  secret_map = jsondecode(var.my_json_variable)
  
  # OR, if you defined it manually
  # secret_map = { "DB_NAME" = "my_db", "API_KEY" = "123" }
}