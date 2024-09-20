// Define parameters for VM configuration
param env string 
param where string 
param vmNames array
param vmSizes array
param keyVaultName string
param adminUsername string
param objectId string
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
// Define the virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: 'winVNet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: ['192.168.57.0/24']
    }
    subnets: [
      {
        name: 'winSubnet'
        properties: {
          addressPrefix: '192.168.57.0/28'
        }
      }
    ]
  }
}

// Define network interfaces and virtual machines in a loop
resource nics 'Microsoft.Network/networkInterfaces@2023-02-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-nic'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPs[i].id
          }
          subnet: {
            id: '${vnet.id}/subnets/winSubnet'
            properties: {
            networkSecurityGroup: {
              id: nsg.id  // Attach the NSG to the subnet
            }
          }
          }
        }
      }
    ]
  }
}]
resource publicIPs 'Microsoft.Network/publicIPAddresses@2023-02-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-pubip'
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
      }
  }
]

// Network Security Group (NSG)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: 'winNSG'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'allow-rdp'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
resource vms 'Microsoft.Compute/virtualMachines@2023-03-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-${env}-${where}'
  location: resourceGroup().location
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


