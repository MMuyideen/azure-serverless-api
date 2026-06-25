resource "azurerm_resource_group" "resource_group" {
  name  = var.rg-name
  location = var.location
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

#Create Resource Group
resource "azurerm_storage_account" "fn_storage_account" {
  name                     = var.fn_storage_account_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create App Service Plan
resource "azurerm_service_plan" "fn_app_service_plan" {
  name                   = var.fn_app_service_plan_name
  location               = azurerm_resource_group.resource_group.location
  resource_group_name    = azurerm_resource_group.resource_group.name
  os_type                = "Linux"
  zone_balancing_enabled = true
  sku_name               = "EP1"
  worker_count = 3
  maximum_elastic_worker_count = 3
}

# Create Azure Application Insights
resource "azurerm_application_insights" "appinsights" {
  name                = "example-appinsights"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "web"
}

resource "azurerm_function_app" "fn_app" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.resource_group.location
  resource_group_name        = azurerm_resource_group.resource_group.name
  app_service_plan_id        = azurerm_service_plan.fn_app_service_plan.id
  storage_account_name       = azurerm_storage_account.fn_storage_account.name
  storage_account_access_key = azurerm_storage_account.fn_storage_account.primary_access_key

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    WEBSITE_WORKER_INDEX = "1"
    FUNCTIONS_EXTENSION_VERSION = "~4"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "1"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.appinsights.instrumentation_key
  }
  
  site_config {
    application_stack {
      python_version = "3.9"
    }
    cors {
      allowed_origins     = ["portal.azure.com"]
    }
  }
}

# create function
resource "azurerm_function_app_function" "function" {
  name            = "httpbin"
  function_app_id = azurerm_function_app.fn_app.id
  language        = "Python"
  file {
    name    = "function_app.py"
    content = file("python function/function_app.py")
  }
  file {
    name    = "host.json"
    content = file("python function/host.json")
  }
  file {
    name    = "requirements.txt"
    content = file("python function/requirements.txt")
  }
  test_data = jsonencode({
    "name" = "Azure"
  })
  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "function"
        "direction" = "in"
        "methods" = [
          "get",
          "post",
        ]
        "name" = "req"
        "type" = "httpTrigger"
      },
      {
        "direction" = "out"
        "name"      = "$return"
        "type"      = "http"
      },
    ]
  })
}

# Create API Management
resource "azurerm_api_management" "demo-apim" {
  name                = var.apim_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  publisher_name      = "publisher"
  publisher_email     = "publisher.email@gmail.com"

  sku_name = "Developer_1"
}

# Create Azure Front Door
resource "azurerm_frontdoor" "backend-demo-frontdoor" {
  name                                         = "prj-backend-demo-${var.environment}"
  resource_group_name                          = var.rg-name

  routing_rule {
    name               = "apim-rule-${var.environment}"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["backend-demo-frontdoor-${var.environment}"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "backend-apim-pool-${var.environment}"
    }
  }

  backend_pool_load_balancing {
    name = "exampleLoadBalancingSettings1"
  }

  backend_pool_health_probe {
    name = "exampleHealthProbeSetting1"
  }

  backend_pool {
    name = "backend-apim-pool-${var.environment}"
    backend {
      host_header = split("://", azurerm_api_management.demo-apim.gateway_url)[1]
      address     = split("://", azurerm_api_management.demo-apim.gateway_url)[1]
      http_port   = 80
      https_port  = 443
      weight = 100
    }

    load_balancing_name = "exampleLoadBalancingSettings1"
    health_probe_name   = "exampleHealthProbeSetting1"
  }

  frontend_endpoint {
    name      = "backend-demo-frontdoor-${var.environment}"
    host_name = "deen-backend-demo-${var.environment}.azurefd.net"
    session_affinity_enabled = true
    session_affinity_ttl_seconds = 300
  }

  depends_on = [azurerm_api_management.demo-apim]
}

# Create Azure Event Hub namespace
resource "azurerm_eventhub_namespace" "example" {
  name                = "prj-eventhub-namespace"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
  capacity            = 1
}

# Create namespace auth
resource "azurerm_eventhub_namespace_authorization_rule" "example" {
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_eventhub_namespace.example.name
  name                = "example-eventhub-authrule"
  send                = true
}

# Create Azure Event Hub
resource "azurerm_eventhub" "example" {
  name                = "prj-eventhub"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.resource_group.name
  partition_count     = 2
  message_retention   = 1
}


# Send App Service logs to Event Hub via App Insights
resource "azurerm_monitor_diagnostic_setting" "example" {
  name               = "prj-diagnostic-setting"
  target_resource_id = azurerm_service_plan.fn_app_service_plan.id
  eventhub_name      = azurerm_eventhub.example.name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.example.id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

