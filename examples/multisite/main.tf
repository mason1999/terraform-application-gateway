// Environment dependency: app_gateway_subnet had CIDR range 10.0.0.0/24
locals {
  resource_group_name     = "arg-application-gateway"
  resource_group_location = "australiaeast"
  app_gateway_subnet_id   = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/nrg-networks/providers/Microsoft.Network/virtualNetworks/shared-vnet/subnets/app-gateway-subnet"
}

// Application Gateway: Configuration
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
    listener_app_1 = {
      name                        = "listener-app-1"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_80.name
      protocol                    = "Http"
      host_name                   = "app1.masondevops.com"
    }
    listener_app_2 = {
      name                        = "listener-app-2"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_80.name
      protocol                    = "Http"
      host_name                   = "app2.masondevops.com"
    }
    listener_app_3 = {
      name                        = "listener-app-3"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_80.name
      protocol                    = "Http"
      host_name                   = "app3.masondevops.com"
    }
    listener_app_4 = {
      name                        = "listener-app-4"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_80.name
      protocol                    = "Http"
      host_name                   = "app4.masondevops.com"
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
    backend_app_1 = {
      name  = "backend-app-1"
      fqdns = ["app1.mydomain.com"]
    }
    backend_app_2 = {
      name  = "backend-app-2"
      fqdns = ["app2.mydomain.com"]
    }
    backend_app_3 = {
      name  = "backend-app-3"
      fqdns = ["app3.mydomain.com"]
    }
    backend_app_4 = {
      name  = "backend-app-4"
      fqdns = ["app4.mydomain.com"]
    }
  }

  request_routing_rules = {
    routing_rule_app_1 = {
      name                       = "routing-rule-app-1"
      http_listener_name         = local.http_listeners.listener_app_1.name
      rule_type                  = "Basic"
      priority                   = 100
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.backend_app_1.name
    }
    routing_rule_app_2 = {
      name                       = "routing-rule-app-2"
      http_listener_name         = local.http_listeners.listener_app_2.name
      rule_type                  = "Basic"
      priority                   = 200
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.backend_app_2.name
    }
    routing_rule_app_3 = {
      name                       = "routing-rule-app-3"
      http_listener_name         = local.http_listeners.listener_app_3.name
      rule_type                  = "Basic"
      priority                   = 300
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.backend_app_3.name
    }
    routing_rule_app_4 = {
      name                       = "routing-rule-app-4"
      http_listener_name         = local.http_listeners.listener_app_4.name
      rule_type                  = "Basic"
      priority                   = 400
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.backend_app_4.name
    }
  }
}

module "example_app_gateway" {
  source                  = "./terraform-application-gateway"
  name                    = "test-app-gateway"
  resource_group_name     = local.resource_group_name
  location                = local.resource_group_location
  subnet_id               = local.app_gateway_subnet_id
  sku_capacity            = 1
  public_ip_configuration = local.public_ip_configuration
  frontend_ports          = local.frontend_ports
  http_listeners          = local.http_listeners
  backend_http_settings   = local.backend_http_settings
  backend_address_pools   = local.backend_address_pools
  request_routing_rules   = local.request_routing_rules
}
