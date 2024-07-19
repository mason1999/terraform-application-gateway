// Environment dependency: app_gateway_subnet had CIDR range 10.0.0.0/24
locals {
  resource_group_name     = "arg-application-gateway"
  resource_group_location = "australiaeast"
  app_gateway_subnet_id   = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/nrg-networks/providers/Microsoft.Network/virtualNetworks/shared-vnet/subnets/app-gateway-subnet"
  key_vault_id            = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/kv-rg/providers/Microsoft.KeyVault/vaults/testkv00000"
  ssl_certificates = {
    app1_mason_devops = {
      name                = "app1-cert"
      key_vault_secret_id = "https://testkv00000.vault.azure.net/secrets/app1-cert/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
    wildcard_mason_devops = {
      name                = "wildcard-cert"
      key_vault_secret_id = "https://testkv00000.vault.azure.net/secrets/wildcard-cert/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
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

    app_2_listener_http = {
      name                        = "app-2-listener-http"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_80.name
      protocol                    = "Http"
      host_name                   = "app2.masondevops.com"
    }

    app_2_listener_https = {
      name                        = "app-2-listener-https"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_443.name
      protocol                    = "Https"
      host_name                   = "app2.masondevops.com"
      ssl_certificate_name        = local.ssl_certificates.wildcard_mason_devops.name
    }

    app_3_listener_http = {
      name                        = "app-3-listener-http"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_80.name
      protocol                    = "Http"
      host_name                   = "app3.masondevops.com"
    }

    app_3_listener_https = {
      name                        = "app-3-listener-https"
      frontend_configuration_name = local.public_ip_configuration.frontend_configuration_name
      frontend_port_name          = local.frontend_ports.port_443.name
      protocol                    = "Https"
      host_name                   = "app3.masondevops.com"
      ssl_certificate_name        = local.ssl_certificates.wildcard_mason_devops.name
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

    app_2_backend = {
      name  = "app-2-backend"
      fqdns = ["app2.mydomain.com"]
    }

    app_3_backend = {
      name  = "app-3-backend"
      fqdns = ["app3.mydomain.com", "app4.mydomain.com"]
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
    request_routing_rule_2_http = {
      name                       = "request-routing-rule-2-http"
      http_listener_name         = local.http_listeners.app_2_listener_http.name
      rule_type                  = "Basic"
      priority                   = 200
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.app_2_backend.name
    }
    request_routing_rule_2_https = {
      name                       = "request-routing-rule-2-https"
      http_listener_name         = local.http_listeners.app_2_listener_https.name
      rule_type                  = "Basic"
      priority                   = 202
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.app_2_backend.name
    }
    request_routing_rule_3_http = {
      name                       = "request-routing-rule-3-http"
      http_listener_name         = local.http_listeners.app_3_listener_http.name
      rule_type                  = "Basic"
      priority                   = 300
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.app_3_backend.name
    }
    request_routing_rule_3_https = {
      name                       = "request-routing-rule-3-https"
      http_listener_name         = local.http_listeners.app_3_listener_https.name
      rule_type                  = "Basic"
      priority                   = 303
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.app_3_backend.name
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
