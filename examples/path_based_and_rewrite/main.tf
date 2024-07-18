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
    default_backend = {
      name  = "default-backend"
      fqdns = ["app4.mydomain.com"]
    }
  }

  rewrite_rule_sets = {
    default_rewrite_rule_set = {
      name = "default-rewrite-rule-set"
      rewrite_rules = {
        rewrite_rule_1 = {
          name          = "rewrite-rule-1"
          rule_sequence = 100
          conditions = {
            condition_1 = {
              variable = "var_uri_path"
              pattern  = "/app1.*"
            }
          }
          url = {
            path       = "/"
            components = "path_only"
            reroute    = true
          }
        }
        rewrite_rule_2 = {
          name          = "rewrite-rule-2"
          rule_sequence = 100
          conditions = {
            condition_1 = {
              variable = "var_uri_path"
              pattern  = "/app2.*"
            }
          }
          url = {
            path       = "/"
            components = "path_only"
            reroute    = true
          }
        }
        rewrite_rule_3 = {
          name          = "rewrite-rule-3"
          rule_sequence = 100
          conditions = {
            condition_1 = {
              variable = "var_uri_path"
              pattern  = "/app3.*"
            }
          }
          url = {
            path       = "/"
            components = "path_only"
            reroute    = true
          }
        }
      }
    }
  }

  url_path_maps = {
    default_path_map = {
      name                               = "default-path-map"
      default_backend_address_pool_name  = local.backend_address_pools.default_backend.name
      default_backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      path_rule = {
        path_rule_app_1 = {
          name                       = "path-rule-app-1"
          paths                      = ["/app1*"]
          backend_address_pool_name  = local.backend_address_pools.backend_app_1.name
          backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
          rewrite_rule_set_name      = local.rewrite_rule_sets.default_rewrite_rule_set.name # TODO: CHANGED THIS
        }
        path_rule_app_2 = {
          name                       = "path-rule-app-2"
          paths                      = ["/app2*"]
          backend_address_pool_name  = local.backend_address_pools.backend_app_2.name
          backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
          rewrite_rule_set_name      = local.rewrite_rule_sets.default_rewrite_rule_set.name # TODO: CHANGED THIS
        }
        path_rule_app_3 = {
          name                       = "path-rule-app-3"
          paths                      = ["/app3*"]
          backend_address_pool_name  = local.backend_address_pools.backend_app_3.name
          backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
          rewrite_rule_set_name      = local.rewrite_rule_sets.default_rewrite_rule_set.name # TODO: CHANGED THIS
        }
      }
    }
  }

  request_routing_rules = {
    default_request_routing_rule = {
      name                       = "default-request-routing-rule"
      http_listener_name         = local.http_listeners.default_http_listener.name
      rule_type                  = "PathBasedRouting"
      priority                   = 100
      backend_http_settings_name = local.backend_http_settings.default_backend_http_settings.name
      backend_address_pool_name  = local.backend_address_pools.default_backend.name
      url_path_map_name          = local.url_path_maps.default_path_map.name
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
  rewrite_rule_sets       = local.rewrite_rule_sets
  url_path_maps           = local.url_path_maps
  request_routing_rules   = local.request_routing_rules
}
