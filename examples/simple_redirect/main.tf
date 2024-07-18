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
      name = "default-backend-pool"
    }
  }

  redirect_configurations = {
    redirect_to_http_bin = {
      name          = "redirect-to-httpbin"
      redirect_type = "Temporary"
      target_url    = "http://httpbin.org"
    }
  }

  request_routing_rules = {
    default_request_routing_rule = {
      name                        = "default-request-routing-rule"
      http_listener_name          = local.http_listeners.default_http_listener.name
      rule_type                   = "Basic"
      priority                    = 101
      redirect_configuration_name = local.redirect_configurations.redirect_to_http_bin.name
    }
  }
}

// Note: the backend_http_settings and backend_address_pools are required for provisioning but do not do anything in this example. 
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
  redirect_configurations = local.redirect_configurations
}
