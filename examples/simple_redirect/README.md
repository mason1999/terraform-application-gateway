## Example -- Simple Redirect

This example demonstrates the minimum requirements for provisioning the Application Gateway with a simple redirection. No backends are configured. A simple redirection page is configured to a `http` website `httpbin.org`. This can be helpful if you want to simply provision the Application Gateway and then clickops settings in later.

To provision this example:

1. Ensure that `resource_group_name` is a valid resource group.
1. Ensure that `app_gateway_subnet_id` is the id of a valid subnet (reccomended size `/24` for ease).
