// Define parameters for VM configuration
param env string 
param location string 
param vmNames array
param vmSizes array
param keyVaultName string
param adminUsername string
param objectId string
param bpublicIpName string
param firewallPublicIpName string
param hvnet string
param svnet string
@secure()
param adminPassword string

// Create a Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: objectId
        permissions: {
          secrets: ['get', 'list', 'set', 'delete']
        }
      }
    ]
  }
}
module vmIP 'mvnetandsubnets.bicep' = { params: {
  location: location
  bpublicIpName: bpublicIpName
  firewallPublicIpName: firewallPublicIpName
  hvnet: hvnet
  svnet: svnet
}
  name: 'virtualMachineIP'
 }
// Define network interfaces and virtual machines in a loop
resource nics 'Microsoft.Network/networkInterfaces@2023-02-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${vmName}-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
            subnet: {
            id: vmIP.outputs.ssubnetIds[i].resourceId
            }
              }
      }
    ]
  }
}]
resource vms 'Microsoft.Compute/virtualMachines@2023-03-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-${env}-${location}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSizes[i]  // Use the corresponding VM size from the array
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
              }
      osDisk: {
        name: '${vmName}-${env}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    securityProfile: {
      encryptionAtHost: true  // Enable disk encryption at host
    }
        osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id  // Reference the NIC for the VM
        }
      ]
    }
  }
  }]
// Store VM credentials in Key Vault as secrets
resource vmUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = [for (vmName, i) in vmNames: {
  parent: keyVault
  name: '${vmName}-${env}-adminUsername'
  properties: {
    value: adminUsername
  }
}]

resource vmPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = [for (vmName, i) in vmNames: {
  parent: keyVault
  name: '${vmName}-${env}-adminPassword'
  properties: {
    value: adminPassword
  }
}]


