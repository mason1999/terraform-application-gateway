variable "name" {
  description = "(Required) The name of the Application Gateway. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group in which to the Application Gateway should exist. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "(Required) The Azure region where the Application Gateway should exist. Changing this forces a new resource to be created."
  type        = string
}

variable "subnet_id" {
  description = "(Required) The id of the subnet where the Application Gateway should be associated to."
  type        = string
}

variable "sku_capacity" {
  description = <<EOF
  (Optional) The Capacity of the SKU to use for this Application Gateway. This value must be between 1 to 125. Required if autoscale_configuration block isn't configured.

  Note: This parameter cannot be used with autoscale_configuration. They are mutually exclusive.
  EOF
  type        = number
  default     = null
}

variable "autoscale_configuration" {
  description = <<EOF
  (Optional) The auto-scaled capacity of the SKU to use for this Application Gateway. An autoscale_configuration block is defined below:

  min_capacity - (Required) Minimum capacity for autoscaling. Accepted values are in the range 0 to 100.
  max_capacity - (Optional) Maximum capacity for autoscaling. Accepted values are in the range 2 to 125.

  Note: This parameter cannot be used with sku_capacity. They are mutually exclusive.
  EOF

  type = object({
    min_capacity = optional(number, null)
    max_capacity = optional(number, null)
  })

  default = {}
}

variable "public_ip_configuration" {
  description = <<EOF
  (Required) Configuration for public ip resource. public_ip_configuration block is defined below:

  name - (Required) Specifies the name of the Public IP. Changing this forces a new Public IP to be created.
  frontend_configuration_name - (Required) The name of the public frontend ip connfiguration.
  ip_version - (Optional) One of the values [IPv4, IPv6]. Defaults to IPv4.
  domain_name_label - (Optional) Label for the domain name. Will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS sytem. Defaults to null.
  zones - (Optional) A collection containing the availability zone to allocate the Public IP in. Changing this creates a new public IP resource. Defaults to [].
  ddos_protection_mode - (Optional) The DDoS protection mode of the public IP. Possible values are Disabled, Enabled, and VirtualNetworkInherited. Defaults to VirtualNetworkInherited.
  ddos_protection_plan_id - (Optional) The ID of DDoS protection plan associated with the public IP. public_ip_ddos_protection_plan_id can only be set when public_ip_ddos_protection_mode is 'Enabled'.
  EOF
  type = object({
    public_ip_name              = string
    frontend_configuration_name = string
    ip_version                  = optional(string, "IPv4")
    domain_name_label           = optional(string, null)
    zones                       = optional(list(string), [])
    ddos_protection_mode        = optional(string, null)
    ddos_protection_plan_id     = optional(string, null)
  })

  validation {
    condition     = contains(["IPv4", "IPv6"], var.public_ip_configuration.ip_version)
    error_message = "ip_version must be one of [IPv4, IPv6]."
  }

  validation {
    condition     = length(setsubtract(var.public_ip_configuration.zones, ["1", "2", "3"])) == 0
    error_message = "zones must be a list consisting of the following values: [1, 2, 3]."
  }
}

variable "private_ip_configurations" {
  description = <<EOF
  (Optional) private_ip_configurations block for private networking as defined below:

  frontend_configuration_name - (Required) The name of the public frontend ip configuration.
  subnet_id - (Required) The ID of the subnet for the private configuration.
  private_ip_address_allocation - (Optional)  The Allocation Method for the Private IP Address. Possible values are Dynamic and Static. Defaults to Dynamic.
  private_ip_address - (Optional) The Private IP Address to use for the Application Gateway.
  EOF
  type = map(object({
    frontend_configuration_name   = string
    subnet_id                     = string
    private_ip_address_allocation = optional(string, null)
    private_ip_address            = optional(string, null)
  }))

  default = {}
}

variable "frontend_ports" {
  description = <<EOF
  (Required) One or more frontend_port blocks as defined below:

  name - (Required) The name of the Frontend Port.
  port - (Required) The port used for this Frontend Port.
  EOF
  type = map(object({
    name = string
    port = number
  }))
}

variable "ssl_certificates" {
  description = <<EOF
  (Optional) One or more http_listener blocks as defined below. Required if you want to use HTTPS on your listeners.

  name - (Required) The Name of the SSL certificate that is unique within this Application Gateway
  key_vault_secret_id - (Optional) The Secret ID of (base-64 encoded unencrypted pfx) the Secret or Certificate object stored in Azure KeyVault.

  EOF
  type = map(object({
    name                = string
    key_vault_secret_id = string
  }))

  default = null
}

variable "http_listeners" {
  description = <<EOF
  (Required) One or more http_listener blocks as defined below:

  name - (Required) The Name of the HTTP Listener.
  frontend_configuration_name - (Required) The Name of the Frontend IP Configuration used for this HTTP Listener.
  frontend_port_name - (Required) The Name of the Frontend Port use for this HTTP Listener.
  protocol - (Required) The Protocol to use for this HTTP Listener. Possible values are Http and Https.
  host_name - (Optional) The Hostname which should be used for this HTTP Listener. Setting this value changes Listener Type to 'Multi site'. If host_name is set host_names cannot be set.
  host_names - (Optional) A list of Hostname(s) should be used for this HTTP Listener. It allows special wildcard characters. If host_names is set host_name cannot be set
  ssl_certificate_name - (Optional) The name of the associated SSL Certificate which should be used for this HTTP Listener.
  custom_error_configurations - (Optional) One or more custom_error_configuration blocks as defined below.

  A custom_error_configuration block supports the following:
  status_code - (Required) Status code of the application gateway customer error. Possible values are HttpStatus403 and HttpStatus502
  custom_error_page_url - (Required) Error page URL of the application gateway customer error.

  EOF
  type = map(object({
    name                        = string
    frontend_configuration_name = string
    frontend_port_name          = string
    protocol                    = string
    host_name                   = optional(string, null)
    host_names                  = optional(list(string), null)
    ssl_certificate_name        = optional(string, null)
    custom_error_configurations = optional(map(object({
      status_code           = string
      custom_error_page_url = string
    })), null)
  }))

  validation {
    condition     = alltrue([for _, v in var.http_listeners : contains(["Http", "Https"], v.protocol)])
    error_message = "protocol must be one of [Http, Https]."
  }
}

variable "probes" {
  description = <<EOF
  (Optional) One or more probe blocks as defined below.

  name - (Required) The Name of the Probe.
  protocol - (Required) The Protocol used for this Probe. Possible values are Http and Https.
  path - (Required) The Path used for this Probe.
  interval - (Required) The Interval between two consecutive probes in seconds. Possible values range from 1 second to a maximum of 86,400 seconds.
  timeout - (Required) The Timeout used for this Probe, which indicates when a probe becomes unhealthy. Possible values range from 1 second to a maximum of 86,400 seconds.
  unhealthy_threshold - (Required) The Unhealthy Threshold for this Probe, which indicates the amount of retries which should be attempted before a node is deemed unhealthy. Possible values are from 1 to 20.
  host - (Optional) The Hostname used for this Probe. If the Application Gateway is configured for a single site, by default the Host name should be specified as 127.0.0.1, unless otherwise configured in custom probe. Cannot be set if pick_host_name_from_backend_http_settings is set to true.
  port - (Optional) Custom port which will be used for probing the backend servers. The valid value ranges from 1 to 65535. In case not set, port from HTTP settings will be used. This property is valid for Standard_v2 and WAF_v2 only.
  pick_host_name_from_backend_http_settings - (Optional) Whether the host header should be picked from the backend HTTP settings. Defaults to false.
  minimum_servers - (Optional) The minimum number of servers that are always marked as healthy. Defaults to 0.
  match - (Optional) A match block as defined below.

  A match block consists of the following properties:

  status_code - (Required) A list of allowed status codes for this Health Probe. Default range of healthy status codes is 200-399.
  body - (Optional) A snippet from the Response Body which must be present in the Response.
  EOF
  type = map(object({
    name                                      = string
    protocol                                  = string
    path                                      = string
    interval                                  = number
    timeout                                   = number
    unhealthy_threshold                       = number
    host                                      = optional(string, null)
    port                                      = optional(number, null)
    pick_host_name_from_backend_http_settings = optional(bool, false)
    minimum_servers                           = optional(number, 0)
    match = optional(object({
      status_code = list(string)
      body        = optional(string, null)
    }), null)
  }))

  validation {
    condition     = alltrue([for _, v in var.probes : contains(["Http", "Https"], v.protocol)])
    error_message = "protocol must be one of [Http, Https]."
  }

  default = {}
}

variable "backend_http_settings" {
  description = <<EOF
  (Required) One or more backend_http_settings blocks as defined below:

  name - (Required) The name of the Backend HTTP Settings Collection.
  cookie_based_affinity - (Required) Is Cookie-Based Affinity enabled? Possible values are Enabled and Disabled.
  port - (Required) The port which should be used for this Backend HTTP Settings Collection.
  protocol - (Required) The Protocol which should be used. Possible values are Http and Https.

  probe_name - (Optional) The name of an associated HTTP Probe.
  affinity_cookie_name - (Optional) The name of the affinity cookie.
  path - (Optional) The Path which should be used as a prefix for all HTTP requests.
  request_timeout - (Optional) The request timeout in seconds, which must be between 1 and 86400 seconds. Defaults to 30.
  host_name - (Optional) Host header to be sent to the backend servers. Cannot be set if pick_host_name_from_backend_address is set to true.
  pick_host_name_from_backend_address - (Optional) Whether host header should be picked from the host name of the backend server. Defaults to false.
  connection_draining - (Optional) A connection_draining block as defined below.

  A connection_draining block supports the following.
  enabled - (Required) If connection draining is enabled or not.
  drain_timeout_sec - (Required) The number of seconds connection draining is active. Acceptable values are from 1 second to 3600 seconds.

  EOF
  type = map(object({
    name                                = string
    cookie_based_affinity               = string
    port                                = number
    protocol                            = string
    probe_name                          = optional(string, null)
    affinity_cookie_name                = optional(string, null)
    path                                = optional(string, null)
    request_timeout                     = optional(number, null)
    host_name                           = optional(string, null)
    pick_host_name_from_backend_address = optional(bool, false)
    connection_draining = optional(object({
      enabled           = bool
      drain_timeout_sec = number
    }), null)
  }))

  validation {
    condition     = alltrue([for _, v in var.backend_http_settings : contains(["Enabled", "Disabled"], v.cookie_based_affinity)])
    error_message = "cookie_based_affinity must be one of [Enabled, Disabled]."
  }

  validation {
    condition     = alltrue([for _, v in var.backend_http_settings : contains(["Http", "Https"], v.protocol)])
    error_message = "protocol must be one of [Http, Https]."
  }
}

variable "backend_address_pools" {
  description = <<EOF
  (Required) One or more backend_address_pool blocks as defined below:

  name - (Required) The name of the Backend Address Pool.
  fqdns - (Optional) A list of FQDN's which should be part of the Backend Address Pool.
  ip_addresses - (Optional) A list of IP Addresses which should be part of the Backend Address Pool.

  EOF
  type = map(object({
    name         = string
    fqdns        = optional(list(string), null)
    ip_addresses = optional(list(string), null)
  }))
}

variable "redirect_configurations" {
  description = <<EOF
  (Optional) One or more redirect_configurations blocks as defined below.

  name - (Required) Unique name of the redirect configuration block
  redirect_type - (Required) The type of redirect. Possible values are Permanent, Temporary, Found and SeeOther
  target_url - (Optional) The URL to redirect the request to. Cannot be set if target_listener_name is set.
  include_path - (Optional) Whether to include the path in the redirected URL. Defaults to false
  include_query_string - (Optional) Whether to include the query string in the redirected URL. Default to false
  target_listener_name - (Optional) The name of the listener to redirect to. Cannot be set if target_url is set.

  Note: This is to be referenced by name in the request_routing_rule blocks.
  EOF

  type = map(object({
    name                 = string
    redirect_type        = string
    target_url           = optional(string, null)
    include_path         = optional(bool, false)
    include_query_string = optional(bool, false)
    target_listener_name = optional(string, null)
  }))

  validation {
    condition     = alltrue([for _, v in var.redirect_configurations : contains(["Permanent", "Temporary", "Found", "SeeOther"], v.redirect_type)])
    error_message = "redirect_type must be one of the following: [Permanent, Temporary, Found, SeeOther]."
  }

  default = {}
}

variable "rewrite_rule_sets" {
  description = <<EOF
  (Optional) One or more of the following rewrite_rule_set blocks. A rewrite_rule_set block supports the following:

  name - (Required) Unique name of the rewrite rule set block
  rewrite_rules - (Optional) One or more rewrite_rule blocks as defined below.

  name - (Required) Unique name of the rewrite rule block
  rule_sequence - (Required) Rule sequence of the rewrite rule that determines the order of execution in a set.
  conditions - (Optional) One or more condition blocks as defined below.
  request_header_configurations - (Optional) One or more request_header_configuration blocks as defined below.
  response_header_configurations - (Optional) One or more response_header_configuration blocks as defined below.
  url - (Optional) One url block as defined below. 

  A condition block supports the following:
  variable - (Required) The variable of the condition.
  pattern - (Required) The pattern, either fixed string or regular expression, that evaluates the truthfulness of the condition.
  ignore_case - (Optional) Perform a case in-sensitive comparison. Defaults to false
  negate - (Optional) Negate the result of the condition evaluation. Defaults to false

  A request_header_configuration block supports the following:
  header_name - (Required) Header name of the header configuration.
  header_value - (Required) Header value of the header configuration. To delete a request header set this property to an empty string.

  A response_header_configuration block supports the following:
  header_name - (Required) Header name of the header configuration.
  header_value - (Required) Header value of the header configuration. To delete a response header set this property to an empty string.

  A url block supports the following:
  path - (Optional) The URL path to rewrite.
  query_string - (Optional) The query string to rewrite.
  components - (Optional) The components used to rewrite the URL. Possible values are path_only and query_string_only to limit the rewrite to the URL Path or URL Query String only.
  reroute - (Optional) Whether the URL path map should be reevaluated after this rewrite has been applied. More info on rewrite configuration
  EOF

  type = map(object({
    name = string
    rewrite_rules = optional(map(object({
      name          = string
      rule_sequence = number
      conditions = optional(map(object({
        variable    = string
        pattern     = string
        ignore_case = optional(bool, false)
        negate      = optional(bool, false)
      })), null)
      request_header_configurations = optional(map(object({
        header_name  = string
        header_value = string
      })), null)
      response_header_configurations = optional(map(object({
        header_name  = string
        header_value = string
      })), null)
      url = optional(object({
        path         = optional(string, null)
        query_string = optional(string, null)
        components   = optional(string, null)
        reroute      = optional(bool, null)
      }), null)
    })), null)
  }))

  default = {}
}

variable "url_path_maps" {
  description = <<EOF
  (Optional) One or more url_path_map blocks as defined below.

  name - (Required) The Name of the URL Path Map.
  default_backend_address_pool_name - (Optional) The Name of the Default Backend Address Pool which should be used for this URL Path Map. Cannot be set if default_redirect_configuration_name is set.
  default_backend_http_settings_name - (Optional) The Name of the Default Backend HTTP Settings Collection which should be used for this URL Path Map. Cannot be set if default_redirect_configuration_name is set.
  default_redirect_configuration_name - (Optional) The Name of the Default Redirect Configuration which should be used for this URL Path Map. Cannot be set if either default_backend_address_pool_name or default_backend_http_settings_name is set.
  default_rewrite_rule_set_name - (Optional) The Name of the Default Rewrite Rule Set which should be used for this URL Path Map. Only valid for v2 SKUs.
  path_rule - (Required) One or more path_rule blocks as defined below.

  A path_rule block supports the following:

  name - (Required) The Name of the Path Rule.
  paths - (Required) A list of Paths used in this Path Rule.
  backend_address_pool_name - (Optional) The Name of the Backend Address Pool to use for this Path Rule. Cannot be set if redirect_configuration_name is set.
  backend_http_settings_name - (Optional) The Name of the Backend HTTP Settings Collection to use for this Path Rule. Cannot be set if redirect_configuration_name is set.
  redirect_configuration_name - (Optional) The Name of a Redirect Configuration to use for this Path Rule. Cannot be set if backend_address_pool_name or backend_http_settings_name is set.
  rewrite_rule_set_name - (Optional) The Name of the Rewrite Rule Set which should be used for this URL Path Map. Only valid for v2 SKUs.
  firewall_policy_id - (Optional) The ID of the Web Application Firewall Policy which should be used as an HTTP Listener.

  Note: Both default_backend_address_pool_name and default_backend_http_settings_name OR default_redirect_configuration_name should be specified.
  EOF

  type = map(object({
    name                                = string
    default_backend_address_pool_name   = optional(string, null)
    default_backend_http_settings_name  = optional(string, null)
    default_redirect_configuration_name = optional(string, null)
    default_rewrite_rule_set_name       = optional(string, null)
    path_rule = map(object({
      name                        = string
      paths                       = list(string)
      backend_address_pool_name   = optional(string, null)
      backend_http_settings_name  = optional(string, null)
      redirect_configuration_name = optional(string, null)
      rewrite_rule_set_name       = optional(string, null)
    }))
  }))

  default = {}
}

variable "request_routing_rules" {
  description = <<EOF
  (Required) One or more request_routing_rule blocks as defined below:

  name - (Required) The Name of this Request Routing Rule.
  rule_type - (Required) The Type of Routing that should be used for this Rule. Possible values are Basic and PathBasedRouting.
  priority - (Required) Rule evaluation order can be dictated by specifying an integer value from 1 to 20000 with 1 being the highest priority and 20000 being the lowest priority.
  http_listener_name - (Required) The Name of the HTTP Listener which should be used for this Routing Rule.
  backend_http_settings_name - (Optional) The Name of the Backend HTTP Settings Collection which should be used for this Routing Rule. Cannot be set if redirect_configuration_name is set. 
  backend_address_pool_name - (Optional) The Name of the Backend Address Pool which should be used for this Routing Rule. Cannot be set if redirect_configuration_name is set.
  redirect_configuration_name - (Optional) The Name of the Redirect Configuration which should be used for this Routing Rule. Cannot be set if either backend_address_pool_name or backend_http_settings_name is set.
  url_path_map_name - (Optional) The Name of the URL Path Map which should be associated with this Routing Rule.

  Note: backend_address_pool_name, backend_http_settings_name, redirect_configuration_name [AND 1 MORE TBD] are only applicable when rule_type is basic.
  EOF
  type = map(object({
    name                        = string
    rule_type                   = string
    priority                    = number
    http_listener_name          = string
    backend_http_settings_name  = optional(string, null)
    backend_address_pool_name   = optional(string, null)
    redirect_configuration_name = optional(string, null)
    url_path_map_name           = optional(string, null)
  }))

  validation {
    condition     = alltrue([for _, v in var.request_routing_rules : contains(["Basic", "PathBasedRouting"], v.rule_type)])
    error_message = "rule_type must be one of [Basic, PathBasedRouting]."
  }

  validation {
    condition     = alltrue([for _, v in var.request_routing_rules : v.priority >= 1 && v.priority <= 20000])
    error_message = "priority must be between 1 and 20000."
  }
}

variable "custom_error_configurations" {
  description = <<EOF
  (Optional) One or more custom error configuration blocks. A custom_error_configuration block supports the following:

  status_code - (Required) Status code of the application gateway customer error. Possible values are HttpStatus403 and HttpStatus502
  custom_error_page_url - (Required) Error page URL of the application gateway customer error.

  EOF
  type = map(object({
    status_code           = string
    custom_error_page_url = string
  }))

  default = null

}

variable "user_assigned_managed_identity" {
  description = <<EOF
  (Optional) One user assigned managed identity block is defined below. Required when configuring https for a listener or TBD. Setting this creates a managed identity with Key Vault Certificate User role on the designated Key Vault.

  name - (Required) The name of the user assigned managed identity.
  key_vault_id - (Required) The resource ID of the key vault.
  EOF
  type = object({
    name         = string
    key_vault_id = string
  })

  default = null

}
