## Example -- Multisite listener

This example demonstrates the provisioning of the Application Gateway which routes to different backends depending on the sub-domain. In this example, the domain `masondevops.com` is owned by the company `contoso`. Within Azure `masondevops.com` is a public dns zone. It has A records `app1.masondevops.com`, `app2.masondevops.com`, `app3.masondevops.com` and `app4.masondevops.com` which all point to the public Ip address of the Application Gateway. These are then routed based off hostname in the listener settings.

To provision this example:

1. Ensure that `resource_group_name` is a valid resource group.
1. Ensure that `app_gateway_subnet_id` is the id of a valid subnet (reccomended size `/24` for ease).
1. Ensure that you own the domain name `masondevops.com` and have provisioned 4 A records to point the subdomain back to the public ip address of the Application Gateway. If `masondevops.com` does not want to be used, another owned domain may be substituted.
1. You have applications which are provisioned to run with internal private DNS names `app1.mydomain.com`, `app2.mydomain.com`, `app3.mydomain.com`, `app4.mydomain.com`.
