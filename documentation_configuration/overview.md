## Overview

Azure Application Gateway is a layer 7 (OSI) load balancer which allows you to route incoming web traffic to different backend web applications. At it's highest level, the Application Gateway operates at layer 7. This means that it can route the incoming traffic based off `HTTP(S)` requests. This means that it can route incoming traffic to a suitable backend application based off things like domain name (i.e `app1.contoso.com` and `app2.contoso.com`) or url path (i.e `app1.contoso.com/api/getresource`).

## Prerequisites

For SSL/TLS termination or end to end SSL/TLS the following are required:

- Azure Key Vault
- A managed identity with `Key Vault Certificate User` RBAC role over the key vault.

## Features

- SSL/TLS Termination <br>
- End to End Encryption <br>
- Autosclaing <br>
- Zone Redundancy <br>
- Static VIP <br>
- URL- based routing <br>
- Multiple-site hosting <br>
- Redirection <br>
- Session affinity <br>
- Connection draining <br>
- Custom error pages <br>
- Rewrite HTTP headers and URL <br>
- Sizing

## Limitations

- WAF not supported

## Documentation

- To see a list of the features: https://learn.microsoft.com/en-us/azure/application-gateway/features
- Do not use v1 sku: https://learn.microsoft.com/en-us/azure/application-gateway/v1-retirement
- Subnet size of Application Gateway subnet: https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#size-of-the-subnet
- Network Security Groups required for Application Gateway: https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#network-security-groups
- Hosting subdomains (or multiple sites) with the same Application Gateway: https://learn.microsoft.com/en-us/azure/application-gateway/multiple-site-overview and https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-multiple-sites-cli
