# Overview

Azure Application Gateway is a layer 7 (OSI) load balancer which allows you to route incoming web traffic to different backend web applications. At it's highest level, the Application Gateway operates at layer 7. This means that it can route the incoming traffic based off `HTTP(S)` requests. This means that it can route incoming traffic to a suitable backend application based off things like domain name (i.e `app1.contoso.com` and `app2.contoso.com`) or url path (i.e `app1.contoso.com/api/getresource`).

## Notes

### Listeners

- To provision app-gateway: You must use have at least one listener configured before using application gateway. [see here](https://learn.microsoft.com/en-us/azure/application-gateway/features)
- Listener function: listens to unique `(protocol, port, hostname, ip-address)`. IT JUST LISTENS
- Listener types: Basic (single domain site) and multi-site (multi-site). Multi-site is used for different domains and sub-domains. Can define wild-card hostname for multi-site listener.
- Priority........?

### Request routing rule

- function: Directs traffic to a backend or another place. specifically:
  - basic request routing rule: dends to associated backend pool
  - path based: routes traffic ot backend pool based on url.
- 1:1 relationship with listener
- Redirection: Can redirect to another listener (HTTP -> HTTPS). Can be temporary or permanent redirection. Can append the path and query to redirected url.
- rewrite headers and url: Can add, remove or update headers and url / queries
- App gateway also inserts 6 additional headers to all requests before it goes to the backend found [here](https://learn.microsoft.com/en-us/azure/application-gateway/how-application-gateway-works#modifications-to-the-request):

  - `x-forwarded-for`: comma-separated list of `IP:port`.
  - `x-original-url`: not explicitly talked about
  - `x-forwarded-proto`: `HTTPS` or `HTTPS`
  - `x-forwarded-port`: Port where request reached app gateway
  - `x-original-host`: original host header
  - `x-appgw-trace-id`: unique guid generated by app gateway for each client request and presented in the `forwarded request` to the backend pool member.

### HTTP Settings

- Further settings to configure things like: end to end TLS or unencrypted
- cookie-based session affinity (same session)
- connection draining: gracefully remove backend pool members
- Custom probes to monitor backend health.
- specifies the protocol, port and other seetings that are required to estalish a new session with the backend server which was picked.

### Backend pools

- Contains: NIC's, VMSS, IP addresses (including public, private or FQDN)
- Use internal IP's you need VNET peering according to [this](https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-components#backend-pools)

## Configuration

### Infrastructure

#### vnet & subnet

- Dedicated subnet for app-gateway (can have 1 or more but can't mix skus)
- 1 private ip addresss per app gateway
- 1 private ip address if configured
- minimum reccomended size subnet [found here](https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#size-of-the-subnet)
  - For standard v1 reccomended is `/26` because 32 (max for v1) + 5 (azure reserved) + 1 (potential private frontend config) = 38 < 64 = $2^6$
  - For standard v2 reccomended is `/24` because 125 (max for v2) + 5 + 1 = 131 < 256 = $2^8$
- Tip: assign addresses from the higher ip address to lower (not from lower to higher)

#### Permissions

- Users and managed identities need at least these permissions `Microsoft.Network/virtualNetworks/subnets/join/action` and `Microsoft.Network/virtualNetworks/subnets/read`. Can use the inbuilt `network contributor` role.

#### NSG rules

- Inbound rules found [here](https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#inbound-rules)
  - **Client traffic**: `Source IP` = as needed, `Source Port` = any, `Destination IP` = subnet IP prefix, `Destination Port` = listener ports (e.g 80 and 443), `Protocol` = TCP, `Access` = Allow
  - **Client traffic with active public and private listeners with the same port number**: `Source IP` = as needed, `Source Port` = any, `Destination IP` = **public/private frontend IP's**, `Destination Port` = listener ports (e.g 80 and 443), `Protocol` = TCP, `Access` = Allow
  - **Infrastructure Ports**: `Source IP` = `GatewayManager`, `Source Port` = any, `Destination IP` = any, `Destination Port` = 65200-65535 (v2) or 65503-65534 (v1), `Protocol` = TCP, `Access` = Allow
  - **Azure Load balancer probes (Created by default)**: `Source IP` = `AzureLoadBalancer`, `Source Port` = any, `Destination IP` = any, `Destination Port` = any, `Protocol` = any, `Access` = Allow
- Outbound rules found [here](https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#outbound-rules)
  - **Outbound to the internet (Created by default. You must not deny outbound connectivity)**: `Source IP` = any, `Source Port` = any, `Destination IP` = `Internet`, `Destination Port` = any, `Protocol` = any, `Access` = Allow

### Frontend IP address

- App gateway V2 Can have public or private ip address or just public ip address.
- private ip address is statically defined from subnet of app gateway.

### Listeners

- Listens on (`port`, `protocol`, `host`, `ip-address`)
- At least one listener is needed to create app gateway. Azure creates one for you by default when you go via portal.
- Listener type:
  - basic: forwards directly to a backend pool
  - multisite: forwards to a backend pool based on host header.
- priority: lower number => higher priority. Priority should be non-wild card listeners --> wild card listeners.
- port:
  - HTTP: traffic from client --> app-gateway is unencrypted
  - HTTPS: TLS termination / end-to-end TLS encryption.
    - To configure TLS termination, a TLS certificate must be added to the listener. Must be in PFX format.
    - To configure end-to-end TLS encryption configure HTTPS in backend HTTP setting as well.
- customer error pages: supported

### Request Routing Rules

- basic RRR: forward all requests on associated listener (e.g blog.contoso.com/\*) --> single backend pool.
- path based RRR: url paths --> backend pools
- Processing rules order: processed in the order that paths are listed in the URL path map. If request matches pattern of two or more paths, first one listed is matched. Make sure that you process rules in correct order listed [here](https://learn.microsoft.com/en-us/azure/application-gateway/multiple-site-overview#request-routing-rules-evaluation-order)
- HTTPS settings play role in routing to the correct backend target
  - for basic RRR: only one backend HTTP setting is allowed. This decides the backend
  - for path based RRR: one backend HTTP settings to each URL path. Again the backend HTTP settings decide the backend. Default HTTP setting for requests that don't match any URL path and are forwarded to the:w
    default backend.
- Redirection settings: if basic RRR, all requests are redirected to the target. If path based RRR, requests adhering to a certain path are redirected to the target.
  - The target can be listener or external site.
  - The type can be 301 (Permanenet), 307 (Temporary), 302 (Found) or 303 (See ot:w
    her).
- Rewrite HTTP headers: Add/remove/update HTTP(S) requests and response headers | URLS | query paths. You can statically set server variables and use them as parameteres in the redirection.

### HTTP Settings

- cookie based affinity: connects client to specific backend server
- connection draining: Gracefully removed backend pool members during updates
- Protocol:
  - HTTP: traffic to backend is unencrypted
  - HTTPS: traffic to backend is encrypted (configure certificates: either use well known CA or self-signed/internal CA. Upload in .CER format)
- Port: where the backend server listens to traffic from app gateway
- Request timeout: Time to wait to receive response from backend server
- Override backend path:
  - BASIC RRR: override backend path is **pre-pended** to the original request.
  - PATH BASED RRR: Override backend path **overrides** path rule (if possible) or **pre-pends** if not.
- Can configure hostname 2 ways:
  - Pick hostname from backend address: Pick one **from backend**
  - Host name override: Override with **constant**.

## Features

[] SSL/TLS Termination <br>
[] End to End Encryption <br>
[] Autosclaing <br>
[] Zone Redundancy <br>
[] Static VIP <br>
[] URL- based routing <br>
[] Multiple-site hosting <br>
[] Redirection <br>
[] Session affinity <br>
[] Connection draining <br>
[] Custom error pages <br>
[] Rewrite HTTP headers and URL <br>
[] Sizing

## Limitations

- List any limitations of the module here

## Documentation

- To see a list of the features: https://learn.microsoft.com/en-us/azure/application-gateway/features
- Do not use v1 sku: https://learn.microsoft.com/en-us/azure/application-gateway/v1-retirement