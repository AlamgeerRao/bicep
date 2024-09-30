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
  name: 'virtual-network'
 }
 module firewall  'mfirewallandbastion.bicep' = { params : {
    location: location
    bpublicIpName: bpublicIpName
    firewallPublicIpName: firewallPublicIpName
    hvnet: hvnet
    svnet: svnet
    bastionName: bastionName
    firewallName: firewallName
  }
 
 name: 'firewall-bastion'
 }
 module virtualmachine 'mvmandkeyvault.bicep' = {
  name: 'vm-keyvault'
  params: {
    location: location
    adminPassword: adminPassword
    adminUsername: adminUsername
    bpublicIpName: bpublicIpName
    env: env
    firewallPublicIpName: firewallPublicIpName
    hvnet: hvnet
    keyVaultName: keyVaultName
    objectId: objectId
    svnet: svnet
    vmNames: vmNames
    vmSizes: vmSizes
  }
 
 }
