Switch-AzureMode AzureResourceManager

#List role assignments in the subscription
Get-AzureRoleAssignment

#Check existing role assignments for a particular role definition, at a particular scope to a particular user
Get-AzureRoleAssignment -ResourceGroupName RGTemp -Mail olskoog@microsoft.com -RoleDefinitionName Owner

#List the supported role definitions
Get-AzureRoleDefinition

#This will create a role assignment at a resource group level
New-AzureRoleAssignment -Mail olskoog@microsoft.com -RoleDefinitionName Contributor -ResourceGroupName RGTemp

#This will create a role assignment for a group at a resource group level
New-AzureRoleAssignment -ObjectID <group object ID> -RoleDefinitionName Reader -ResourceGroupName RGTemp

#This will create a role assignment at a resource level
$resources = Get-AzureResource
New-AzureRoleAssignment -Mail olskoog@microsoft.com -RoleDefinitionName Owner -Scope $resources[0].ResourceId
