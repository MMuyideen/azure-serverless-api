output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
  description = "Name of the resource group"
}

output "function_app_name" {
  value = azurerm_function_app.fn_app.name
  description = "Name of the resource group"
}

output "function_app_id" {
  value = azurerm_function_app.fn_app.id
  description = "Id of the function app"
}

output "apim_gateway_url" {
  value = azurerm_api_management.demo-apim.gateway_url
  description = "Gateway URL of the APIM"
}

output "frontdoor_frontend_endpoint" {
  value = azurerm_frontdoor.backend-demo-frontdoor.frontend_endpoint
  description = "Frontdoor endpoint"
}