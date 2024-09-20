// Define parameters for VM configuration
param env string  = 'prod'
param where string = 'uksouth'
param vmName string = 'agentpoolvm1'
param vmSize string = 'Standard_DS1_v2'
//param keyVaultName string
param adminUsername string = 'vmuser'
@secure()
param adminPassword string = 'Welcome!2345'

// Define the virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: 'winVNet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: ['192.168.60.0/24']
    }
    subnets: [
      {
        name: 'linuxSubnet'
        properties: {
          addressPrefix: '192.168.60.0/28'
        }
      }
    ]
  }
}

// Define network interfaces and virtual machines in a loop
resource nics 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${vmName}-nic'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPs.id
          }
          subnet: {
            id: '${vnet.id}/subnets/linuxSubnet'
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
}
resource publicIPs 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: '${vmName}-pubip'
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
      }
  }


// Network Security Group (NSG)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: 'linuxNSG'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
resource vms 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: '${vmName}-${env}-${where}'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize  // Use the corresponding VM size from the array
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer:  '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
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
            osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics.id  // Reference the NIC for the VM
        }
      ]
    }
  }
  }
