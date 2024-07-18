## Example -- Path-based routing with rewrites

This example demonstrates the provisioning of the Application Gateway with path based routing with a simple rewrite condition.

To provision this example:

1. Ensure that `resource_group_name` is a valid resource group.
1. Ensure that `app_gateway_subnet_id` is the id of a valid subnet (reccomended size `/24` for ease).
1. You have applications which are provisioned to run with internal private DNS names `app1.mydomain.com`, `app2.mydomain.com`, `app3.mydomain.com`, `app4.mydomain.com`.
