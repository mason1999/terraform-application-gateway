resource "azurerm_public_ip" "this" {
  name                    = var.public_ip_configuration.public_ip_name
  resource_group_name     = var.resource_group_name
  location                = var.location
  allocation_method       = "Static"
  sku                     = "Standard"
  ip_version              = var.public_ip_configuration.ip_version
  domain_name_label       = var.public_ip_configuration.domain_name_label
  zones                   = var.public_ip_configuration.zones
  ddos_protection_mode    = var.public_ip_configuration.ddos_protection_mode
  ddos_protection_plan_id = var.public_ip_configuration.ddos_protection_plan_id
}

resource "azurerm_user_assigned_identity" "this" {
  count               = var.user_assigned_managed_identity == null ? 0 : 1
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = var.user_assigned_managed_identity.name
}

resource "azurerm_role_assignment" "this" {
  count                = var.user_assigned_managed_identity == null ? 0 : 1
  scope                = var.user_assigned_managed_identity.key_vault_id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = azurerm_user_assigned_identity.this[0].principal_id
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = var.sku_capacity
  }

  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration.min_capacity == null && var.autoscale_configuration.max_capacity == null ? [] : [1]
    content {
      min_capacity = var.autoscale_configuration.min_capacity
      max_capacity = var.autoscale_configuration.max_capacity
    }
  }

  gateway_ip_configuration {
    name      = "${var.name}-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  # Public frontend configuration
  frontend_ip_configuration {
    name                 = var.public_ip_configuration.frontend_configuration_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  # Private frontend configuration
  dynamic "frontend_ip_configuration" {
    for_each = var.private_ip_configurations
    content {
      name                          = frontend_ip_configuration.value.frontend_configuration_name
      subnet_id                     = frontend_ip_configuration.value.subnet_id
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
      private_ip_address            = frontend_ip_configuration.value.private_ip_address
    }
  }

  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  dynamic "identity" {
    for_each = var.user_assigned_managed_identity[*]
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.this[0].id]
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates == null ? {} : var.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      ssl_certificate_name           = http_listener.value.ssl_certificate_name

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configurations == null ? {} : http_listener.value.custom_error_configurations
        content {
          status_code           = custom_error_configuration.value.status_code
          custom_error_page_url = custom_error_configuration.value.custom_error_page_url
        }
      }

    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = probe.value.name
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      host                                      = probe.value.host
      port                                      = probe.value.port
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      minimum_servers                           = probe.value.minimum_servers

      dynamic "match" {
        for_each = probe.value.match[*]
        content {
          status_code = match.value.status_code
          body        = match.value.body
        }
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      probe_name                          = backend_http_settings.value.probe_name
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      path                                = backend_http_settings.value.path
      request_timeout                     = backend_http_settings.value.request_timeout
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining[*]
        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }

  }

  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name                 = redirect_configuration.value.name
      redirect_type        = redirect_configuration.value.redirect_type
      target_url           = redirect_configuration.value.target_url
      include_path         = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
      target_listener_name = redirect_configuration.value.target_listener_name
    }

  }

  # TODO: WRITING THIS
  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_sets
    content {
      name = rewrite_rule_set.value.name
      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rewrite_rules == null ? {} : rewrite_rule_set.value.rewrite_rules
        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.rule_sequence
          dynamic "condition" {
            for_each = rewrite_rule.value.conditions == null ? {} : rewrite_rule.value.conditions
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          }
          dynamic "request_header_configuration" {
            for_each = rewrite_rule.value.request_header_configurations == null ? {} : rewrite_rule.value.request_header_configurations
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }
          dynamic "response_header_configuration" {
            for_each = rewrite_rule.value.response_header_configurations == null ? {} : rewrite_rule.value.response_header_configurations
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }
          dynamic "url" {
            for_each = rewrite_rule.value.url[*]
            content {
              path         = url.value.path
              query_string = url.value.query_string
              components   = url.value.components
              reroute      = url.value.reroute
            }
          }
        }
      }
    }
  }

  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name
      default_redirect_configuration_name = url_path_map.value.default_redirect_configuration_name
      default_rewrite_rule_set_name       = url_path_map.value.default_rewrite_rule_set_name
      dynamic "path_rule" {
        for_each = url_path_map.value.path_rule
        content {
          name                        = path_rule.value.name
          paths                       = path_rule.value.paths
          backend_address_pool_name   = path_rule.value.backend_address_pool_name
          backend_http_settings_name  = path_rule.value.backend_http_settings_name
          redirect_configuration_name = path_rule.value.redirect_configuration_name
          rewrite_rule_set_name       = path_rule.value.rewrite_rule_set_name
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = request_routing_rule.value.rule_type
      priority                    = request_routing_rule.value.priority
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
    }
  }
  dynamic "custom_error_configuration" {
    for_each = var.custom_error_configurations == null ? {} : var.custom_error_configurations
    content {
      status_code           = custom_error_configuration.value.status_code
      custom_error_page_url = custom_error_configuration.value.custom_error_page_url
    }
  }
  # TODO: Zones, trusted_client_certificate, ssl_profile, authentication_certificate, trusted_root_certificate, ssl_policy, ssl_certificate
  depends_on = [azurerm_user_assigned_identity.this, azurerm_role_assignment.this]
}
