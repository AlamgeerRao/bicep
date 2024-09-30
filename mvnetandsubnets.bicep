param location string 
param hvnet string 
param svnet string
param bpublicIpName string
param firewallPublicIpName string
// Object type parameter for two Vnets and five subnets 
param svnetSettings object = {
  svnetAdress : [
    '192.168.57.0/24'
      ]
  subnets : [
    {
    name :'${svnet}-sub1'
    addressPrefix : '192.168.57.0/28'
    }

    {
      name :'${svnet}-sub2'
      addressPrefix : '192.168.57.16/28'
      }
      {
        name :'${svnet}-sub3'
        addressPrefix : '192.168.57.32/28'
        }
                ]
    }
    param hvnetSettings object = {
      hvnetAdress : [
        '10.0.0.0/16'
      ]
      subnets : [
            
      {
         name :'AzureFirewallSubnet'
         addressPrefix : '10.0.2.0/24'
              }
      {
          name :'AzureBastionSubnet'
          addressPrefix : '10.0.1.0/24'
                }
    
          ]
        }
        //to create a network security group to allow rdp
        resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
          name: '${svnet}-default-nsg'
          location: location
          properties: {
            securityRules: [
              {
                name: 'allow-rdp'
                properties: {
                  description: 'allow rdp from bastion'
                  protocol: 'Tcp'
                  sourcePortRange: '*'
                  destinationPortRange: '3389'
                  sourceAddressPrefix: '10.0.1.0/24'
                  destinationAddressPrefix: '*'
                  access: 'Allow'
                  priority: 300
                  direction: 'Inbound'
                }
              }
            ]
          }
        }
  // To add a Rout table and a default route
        resource routeTable 'Microsoft.Network/routeTables@2019-11-01' = {
          name: '${svnet}-default-routetable'
          location: location
            properties: {
              routes: [
                        {
                          name: '${svnet}-default-rt'
                            properties: {
                              addressPrefix: '0.0.0.0/0'
                              nextHopType: 'VirtualAppliance'
                              nextHopIpAddress: '10.0.2.4'
        }
      }
    ]
          disableBgpRoutePropagation: true
  }
}
// Spoke Virtual Network and Subnets
    resource svirtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
      name: '${location}-${svnet}'
      location: location
      properties: {
        addressSpace: {
          addressPrefixes: svnetSettings.svnetAdress
        }
        subnets: [ for subnet in svnetSettings.subnets : {
          name : subnet.name
               properties: {
              addressPrefix: subnet.addressPrefix
              networkSecurityGroup:{
                id:networkSecurityGroup.id
              }
              routeTable: {
                id: routeTable.id
              }
              
            }
            }
          ]
        }
      }
      // Hub Virtual Network and Subnets
          resource hvirtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
            name: '${location}-${hvnet}'
            location: location
            properties: {
              addressSpace: {
                addressPrefixes: hvnetSettings.hvnetAdress
              }
              subnets: [ for subnet in hvnetSettings.subnets : {
                name : subnet.name
                     properties: {
                    addressPrefix: subnet.addressPrefix
                    
                  }
                }
        ]
          }
        
      }
      //output hvnetid string = hvirtualNetwork.name

   resource peeringToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
      name: '${hvnet}_to_${svnet}'
      parent: hvirtualNetwork
      properties: {
        allowVirtualNetworkAccess: true
        allowForwardedTraffic: true
        allowGatewayTransit: true
        useRemoteGateways: false
        remoteVirtualNetwork: {
          id: svirtualNetwork.id
        }
      }
        }
    
    resource peeringTohub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
      name: '${svnet}_to_${hvnet}'
      parent: svirtualNetwork
      properties: {
        allowVirtualNetworkAccess: true
        allowForwardedTraffic: true
        allowGatewayTransit: true
        useRemoteGateways: false
        remoteVirtualNetwork: {
          id: hvirtualNetwork.id
        }
      }
    }
    

      resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
        name: firewallPublicIpName
        location: location
        properties: {
          publicIPAllocationMethod: 'Static'
        }
        sku: {
          name: 'Standard'
        }
      }
      resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
        name: bpublicIpName
        location: location
        properties: {
          publicIPAllocationMethod: 'Static'
        }
        sku: {
          name: 'Standard'
        }
      }
      output ssubnetIds array = [
        for (subnet,i) in svnetSettings.subnets: {
          resourceId:svirtualNetwork.properties.subnets[i].id
        }
      ]
      output hsubnetIds array = [
        for (subnet,i) in hvnetSettings.subnets: {
          resourceId:hvirtualNetwork.properties.subnets[i].id
        }
      ]
      output fpubip string = firewallPublicIP.id
      output bpubip string = bastionPublicIP.id
           // output test string = svirtualNet

    //  output hsubnetIds array = [
      //  for subnet in hvnetSettings.subnets: subnet.name
      //]
output hubvnetid string = hvirtualNetwork.id
output subvnetid string = svirtualNetwork.id
