param location string
param bpublicIpName string
param bastionName string
param hvnet string
param svnet string
param firewallPublicIpName  string

module bpublicIP 'mvnetandsubnets.bicep' = {
  name: 'bastion'
  params: {
    location: location
    bpublicIpName: bpublicIpName
    firewallPublicIpName: firewallPublicIpName
    hvnet: hvnet
    svnet: svnet
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
            id: bpublicIP.outputs.hsubnetIds[1].resourceId
          }
          publicIPAddress: {
            id: bpublicIP.outputs.bpubip
          }
        }
      }
    ]
  }
}
