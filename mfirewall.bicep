param location string
param bpublicIpName string
param firewallPublicIpName string
param hvnet string
param svnet string
param firewallName string 


module fpublicIP 'mvnetandsubnets.bicep' = { params: {
  location: location
  bpublicIpName: bpublicIpName
  firewallPublicIpName: firewallPublicIpName
  hvnet: hvnet
  svnet: svnet
}
  name: 'firewall'
}
resource firewall 'Microsoft.Network/azureFirewalls@2021-05-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'firewallIPConfig'
        properties: {
          subnet: {
            id: fpublicIP.outputs.hsubnetIds[0].resourceId
          }
          publicIPAddress: {
            id: fpublicIP.outputs.fpubip
          }
        }
      }
    ]
  }
}

