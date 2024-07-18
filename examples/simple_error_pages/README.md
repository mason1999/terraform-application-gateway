## Example -- Simple error pages

This example demonstrates the requirements for provisioning the Application Gateway with error pages attached to a http listener and a global error page for the Application Gateway. Two storage accounts are also provisioned to create the error pages.

To provision this example:

1. Ensure that `resource_group_name` is a valid resource group.
1. Ensure that `app_gateway_subnet_id` is the id of a valid subnet (reccomended size `/24` for ease).
1. Ensure that the storage accounts have unique names. In this case they are called `testcontosostore000000` and `testcontosostore000001`.
1. Ensure that you have the files `index_403.html` and `index_502.html`.
