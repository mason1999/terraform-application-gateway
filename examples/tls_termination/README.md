## Example -- ssl/tls termination

This example demonstrates the provisioning of the Application Gateway ssl / tls termination

To provision this example:

1. Ensure that `resource_group_name` is a valid resource group.
1. Ensure that `app_gateway_subnet_id` is the id of a valid subnet (reccomended size `/24` for ease).
1. Ensure that `key_vault_id` is valid.
1. Ensure that you have two certificates in the keyvault: `app1-cert` and `wildcard-cert`.
   - `app1-cert` is only for `app1.masondevops.com`.
   - `wildcard-cert` works for any subdomain one level below `masondevops.com`. So `app2.masondevops.com` and `app3.masondevops.com` would work.
