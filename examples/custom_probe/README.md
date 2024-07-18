## Example -- Custom Probe

This example demonstrates the provisioning of the Application Gateway with a custom probe. The example sets up the custom probe which load balances between two fqdn's in a single backend.

To provision this example:

1. Ensure that `resource_group_name` is a valid resource group.
1. Ensure that `app_gateway_subnet_id` is the id of a valid subnet (reccomended size `/24` for ease).
1. You have applications which are provisioned to run with internal private DNS names `app1.mydomain.com` and `app2.mydomain.com`. Alternatively you could reference the applications with private static IP addresses instead.
