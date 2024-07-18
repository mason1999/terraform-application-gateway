// Environment dependency: app_gateway_subnet had CIDR range 10.0.0.0/24
locals {
  resource_group_name     = "arg-application-gateway"
  resource_group_location = "australiaeast"
  app_gateway_subnet_id   = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/nrg-networks/providers/Microsoft.Network/virtualNetworks/shared-vnet/subnets/app-gateway-subnet"
}

locals {
  public_ip_configuration = {
    public_ip_name              = "app-gateway-pip"
    frontend_configuration_name = "frontend-public"
    domain_name_label           = "mason-app-gateway"
  }

  private_ip_configurations = {
    default_config = {
      frontend_configuration_name   = "frontend-private"
      subnet_id                     = local.app_gateway_subnet_id
      private_ip_address_allocation = "Static"
      private_ip_address            = "10.0.0.254"
    }
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
      name  = "default-backend-pool"
      fqdns = ["app1.mydomain.com"]
    }
  }

  request_routing_rules = {
    default_request_routing_rule = {
      name                       = "default-request-routing-rule"
      http_listener_name         = local.http_listeners.default_http_listener.name
      rule_type                  = "Basic"
      priority                   = 100
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.default_backend_address_pool.name
    }
  }
}

module "example_app_gateway" {
  source                    = "./terraform-application-gateway"
  name                      = "test-app-gateway"
  resource_group_name       = local.resource_group_name
  location                  = local.resource_group_location
  subnet_id                 = local.app_gateway_subnet_id
  sku_capacity              = 1
  public_ip_configuration   = local.public_ip_configuration
  private_ip_configurations = local.private_ip_configurations
  frontend_ports            = local.frontend_ports
  http_listeners            = local.http_listeners
  backend_http_settings     = local.backend_http_settings
  backend_address_pools     = local.backend_address_pools
  request_routing_rules     = local.request_routing_rules
}
