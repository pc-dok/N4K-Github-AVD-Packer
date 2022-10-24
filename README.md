## Lets create Azure AVD complete with Github Workflow and Terraform

[![N|Solid](https://cldup.com/dTxpPi9lDf.thumb.png)](https://nodesource.com/products/nsolid)

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

## N4K-Github-AVD-Packer
Create Azure AVD with a AADDS and Packer Images

On Azure create first a new Contributor Role
az ad sp create contributer command - and dont forget
to give this CLI all the needed Roles

--< az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/yourID" >--

Subscriptions - IAM - there you see all roles, and you can create a assignment
Roles and Assignments for the azure-cli service principal:

> - Contributor
> - Application Administrator Role
> - Domain Service Contributor
> - User Access Administrator
> - Cloud Application Administrator
> - Network Contributor
> - User Administrator

```sh
- Because of higher security we want not save the tfstate files in our repo, so i take terraform workspaces
- You must create in your terraform cloud first for every step 4 different workspaces (up2you)
- Important: It must be a API driven workflow
- every workspace must have the Azure credentials from your created rbac account stored
- also you need in your github - settings - a personal access token generated - this is the github secret
-- GITHUB_OWNER	
-- GITHUB_SECRET
-- ARM_TENANT_ID
-- ARM_SUBSCRIPTION
-- ARM_CLIENT_ID	
-- ARM_CLIENT_SECRET
```

## 1. Create Packer Environment
First - Create Images for the Jumpinghost and the AVD - Server 2022 and Windows 11

```sh
- We will create a Github Repo, add there the Secrets what is needed for Azure
- Than we parsing our files what we are needing to create packer images
- Last step is creating the workflow files
- Now you will see unter Actions - a Packer 11 and a Packer 2022 Workflow - Let it run!
```

- Create a Github Repo
- Create the needed files
- ✨Magic: Github Workflow fully created - let it run ✨


> On the end you should have 2 Images in your Azure Ressource Group. 
> That Images we take later for our Jumping Host, and for the Windows 11 AVD!

## 2. Create the Azure Active Domain Directory Service
We create a AADDS - because i have no onprem AD. And for joining Computers you need an AD :). No more informations need here. code says more!

## 3. Create the Azure Bastion and Jumping Host
After we have create the AADDS i want know if AD is working as expected. For that i create a Jumping Host with Windows Server 2022 (RSAT Tools for AD installed) and join it to the Domain. When this is working i am sure the AVD in Step 4 will than also work for me. For testing i open then the AD Tools, to look if i see my Server in the Computers OU from AADDS!

## 4. Create the Azure Virtual Desktop
In this Step we create the Azure Virtual Deskopts - AVD! In that step i also take the packer Image what we create in Step 1. It is only for Demo so no more info needed here. When you want try to logon you do that over the 

- https://client.wvd.microsoft.com/arm/webclient/index.html

I can than logon with my avduser1 account for demo. please adapt it in your way!

## 5. Your Environment on the End

| Steps   | Info   |
| ------- | ------ |
| Packer  | Create Github Repo for creating Packer Images   |
| AADDS   | Creates Azure Active Directory Service          |
| Bastion | Creates Azure Bastion Service with one Jumphost |
| AVD     | Create the Azure Virtual Desktop                |
| ------- | ------ |
