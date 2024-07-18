## Example -- Simple fqdn backend

This example demonstrates the minimum requirements for provisioning the Application Gateway with a single simple backend. The backend which is configured is a `fqdn`. We have also shown the configuration to enable a private ip setting for the application gateway, but it is not necessary to make this example function. It is only shown for demonstrative purposes.

To provision this example:

1. Ensure that `resource_group_name` is a valid resource group.
1. Ensure that `app_gateway_subnet_id` is the id of a valid subnet (reccomended size `/24` for ease).
1. Ensure that your Application Gateway can connect to your application (via Private Static IP or an fqdn). For example, if the vnet has Address Space `10.0.0.0/16` and if the Application Gateway has Address Space `10.0.0.0/24` then we could use the Address Space `10.0.1.0/24` for applications. This would enable us to have automatic network connectivity.
