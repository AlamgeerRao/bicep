param env string 
param location string 
param vmNames array
param vmSizes array
param keyVaultName string
param adminUsername string
param objectId string
@secure()
param adminPassword string
param hvnet string 
param svnet string 
param firewallPublicIpName string
param firewallName string 
param bastionName string 
param bpublicIpName string

module vnets 'mvnetandsubnets.bicep' = { params: {
  location: location
  bpublicIpName: bpublicIpName
  firewallPublicIpName: firewallPublicIpName
  hvnet: hvnet
  svnet: svnet
}
  name: 'virtual-network-main'
 }
 module firewall  'mfirewall.bicep' = {
  name: 'firewall-main'
  params: {
    location: location
    bpublicIpName: bpublicIpName
    firewallName: firewallName
    firewallPublicIpName: firewallPublicIpName
    hvnet: hvnet
    svnet: svnet
  }
 }
 module bastion 'mbastion.bicep' = {
  name: 'bastion-deployment-main'
  params: {
    location: location
    bastionName: bastionName
    bpublicIpName: bpublicIpName
    firewallPublicIpName: firewallPublicIpName
    hvnet: hvnet
    svnet: svnet
  }
 }
 module keyvault 'mkeyvault.bicep' = {
  name: 'keyvault-deployment-main'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    env:  env
    keyVaultName: keyVaultName
    objectId: objectId
    vmNames: vmNames
  }
 }
   
 module virtualmachine 'mvirtualmachines.bicep' = {
  name: 'vm-keyvault-main'
  params: {
    location: location
    adminPassword: adminPassword
    adminUsername: adminUsername
    bpublicIpName: bpublicIpName
    env: env
    firewallPublicIpName: firewallPublicIpName
    hvnet: hvnet
    svnet: svnet
    vmNames: vmNames
    vmSizes: vmSizes
  }
 
 }
 
