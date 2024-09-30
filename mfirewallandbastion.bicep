param location string
param bpublicIpName string
param firewallPublicIpName string
param hvnet string
param svnet string
param firewallName string = '${location}-prod-firewall1'
param bastionName string = '${location}-prod-bastion'


module fpublicIP 'mvnetandsubnets.bicep' = { params: {
  location: location
  bpublicIpName: bpublicIpName
  firewallPublicIpName: firewallPublicIpName
  hvnet: hvnet
  svnet: svnet
}
  name: 'firewallPublicIP'
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
resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIPConfig'
        properties: {
          subnet: {
            id: fpublicIP.outputs.hsubnetIds[1].resourceId
          }
          publicIPAddress: {
            id: fpublicIP.outputs.bpubip
          }
        }
      }
    ]
  }
}

