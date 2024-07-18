// Environment dependency: app_gateway_subnet had CIDR range 10.0.0.0/24
locals {
  resource_group_name     = "arg-application-gateway"
  resource_group_location = "australiaeast"
  app_gateway_subnet_id   = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/nrg-networks/providers/Microsoft.Network/virtualNetworks/shared-vnet/subnets/app-gateway-subnet"
}

// Storage accounts: Used for the provisioning of error pages
locals {
  storage_accounts = {
    configuration_403 = {
      name       = "testcontosostore000000"
      index_html = "index_403.html"
    }
    configuration_502 = {
      name       = "testcontosostore000001"
      index_html = "index_502.html"
    }
  }
}

resource "azurerm_storage_account" "example" {
  for_each                 = local.storage_accounts
  resource_group_name      = local.resource_group_name
  location                 = local.resource_group_location
  name                     = each.value.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  static_website {
    index_document = each.value.index_html
  }
}

resource "azurerm_storage_blob" "example" {
  for_each               = local.storage_accounts
  name                   = each.value.index_html
  storage_account_name   = each.value.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = each.value.index_html
  depends_on             = [azurerm_storage_account.example]
}

// Application Gateway Configuration: No backends are configured
locals {
  public_ip_configuration = {
    public_ip_name              = "app-gateway-pip"
    frontend_configuration_name = "frontend-public"
    domain_name_label           = "mason-app-gateway"
  }

  frontend_ports = {
    port_80 = {
      name = "frontend-port"
      port = 80
    }
  }

  http_listeners = {
    default_http_listener = {
      name                        = "default-http-listener"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_80.name
      protocol                    = "Http"
      custom_error_configurations = {
        customer_error_configuration_default = {
          status_code           = "HttpStatus502"
          custom_error_page_url = "${azurerm_storage_account.example["configuration_502"].primary_web_endpoint}index_502.html"
        }
      }
    }
  }

  backend_http_settings = {
    default_backend_http_settings = {
      name                  = "default-backend-http-settings"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
    }
  }

  backend_address_pools = {
    default_backend_address_pool = {
      name = "default-backend-pool"
    }
  }

  request_routing_rules = {
    default_request_routing_rule = {
      name                       = "default-request-routing-rule"
      rule_type                  = "Basic"
      priority                   = 101
      http_listener_name         = local.http_listeners.default_http_listener.name
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.default_backend_address_pool.name
    }
  }

  global_custom_error_configurations = {
    default_global_custom_error_configuration = {
      status_code           = "HttpStatus403"
      custom_error_page_url = "${azurerm_storage_account.example["configuration_403"].primary_web_endpoint}index_403.html"
    }
  }
}

module "example_app_gateway" {
  source                      = "./terraform-application-gateway"
  name                        = "test-app-gateway"
  resource_group_name         = local.resource_group_name
  location                    = local.resource_group_location
  subnet_id                   = local.app_gateway_subnet_id
  sku_capacity                = 1
  public_ip_configuration     = local.public_ip_configuration
  frontend_ports              = local.frontend_ports
  http_listeners              = local.http_listeners
  backend_http_settings       = local.backend_http_settings
  backend_address_pools       = local.backend_address_pools
  request_routing_rules       = local.request_routing_rules
  custom_error_configurations = local.global_custom_error_configurations
}

