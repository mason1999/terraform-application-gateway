// Environment dependency: app_gateway_subnet had CIDR range 10.0.0.0/24
locals {
  resource_group_name     = "arg-application-gateway"
  resource_group_location = "australiaeast"
  app_gateway_subnet_id   = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/nrg-networks/providers/Microsoft.Network/virtualNetworks/shared-vnet/subnets/app-gateway-subnet"
  key_vault_id            = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/kv-rg/providers/Microsoft.KeyVault/vaults/testkv00000"
  ssl_certificates = {
    app1_mason_devops = {
      name                = "app1-masondevops"
      key_vault_secret_id = "https://testkv00000.vault.azure.net/secrets/app1-masondevops/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
  }
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
      name = "port-80"
      port = 80
    }
    port_443 = {
      name = "port-443"
      port = 443
    }
  }

  http_listeners = {
    app_1_listener_http = {
      name                        = "app-1-listener-http"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_80.name
      protocol                    = "Http"
      host_name                   = "app1.masondevops.com"
    }

    app_1_listener_https = {
      name                        = "app-1-listener-https"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_443.name
      protocol                    = "Https"
      host_name                   = "app1.masondevops.com"
      ssl_certificate_name        = local.ssl_certificates.app1_mason_devops.name
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
    app_1_backend = {
      name  = "app-1-backend"
      fqdns = ["app1.mydomain.com"]
    }
  }

  request_routing_rules = {
    request_routing_rule_1_http = {
      name                       = "request-routing-rule-1-http"
      http_listener_name         = local.http_listeners.app_1_listener_http.name
      rule_type                  = "Basic"
      priority                   = 100
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.app_1_backend.name
    }
    request_routing_rule_1_https = {
      name                       = "request-routing-rule-1-https"
      http_listener_name         = local.http_listeners.app_1_listener_https.name
      rule_type                  = "Basic"
      priority                   = 101
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.app_1_backend.name
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
  user_assigned_managed_identity = {
    name         = "test-app-gateway-uami"
    key_vault_id = local.key_vault_id
  }
  ssl_certificates = local.ssl_certificates
}
