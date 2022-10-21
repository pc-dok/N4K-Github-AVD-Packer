# N4K-Github-AVD-Packer
Create Azure AVD with a AADDS and Packer Images

On Azure create first a new Contributor Role
az ad sp create contributer command - and dont forget
to give this CLI all the needed Roles

--< az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/yourID" >--

Subscriptions - IAM - there you see all roles, and you can create a assignment
Roles and Assignments for the azure-cli service principal:

Contributor \
Application Administrator Role \
Domain Service Contributor \
User Access Administrator \
Cloud Application Administrator \
Network Contributor \
User Administrator \

// # First - Create Images for the Jumpinghost and the AVD - Server 2022 and Windows 11
