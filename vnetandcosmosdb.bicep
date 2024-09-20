param location string = 'uksouth'
param prefix string = 'toyprj'
param vnetSettings object = {
  vnetAdress : [
    '192.168.57.0/24'
  ]
  subnets : [
    {
    name :'${prefix}-sub1'
    addressPrefix : '192.168.57.0/28'
    }
    {
      name :'${prefix}-sub2'
      addressPrefix : '192.168.57.16/28'
      }
      {
        name :'${prefix}-sub3'
        addressPrefix : '192.168.57.32/28'
        }
      ]
    }
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${prefix}-default-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'nsgRule'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${prefix}-spoke-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetSettings.vnetAdress
    }
    subnets: [ for subnet in vnetSettings.subnets : {
      name : subnet.name
           properties: {
          addressPrefix: subnet.addressPrefix
          networkSecurityGroup:{
            id:networkSecurityGroup.id
          }
        }
      }
    ]
      }
    
  }
  resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {
    name: '${prefix}-cosmos-account'
    location: location
    kind: 'GlobalDocumentDB'
    properties: {
      consistencyPolicy: {
        defaultConsistencyLevel: 'Session'
      }
      locations: [
        {
          locationName: location
          failoverPriority: 0
        }
      ]
      databaseAccountOfferType: 'Standard'
      enableAutomaticFailover: false
      capabilities: [
        {
          name: 'EnableServerless'
        }
      ]
    }
  }
  resource sqlDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
    parent: cosmosDbAccount
    name: '${prefix}-sqldb'  
    properties: {
      resource: {
        id: '${prefix}-sqldb'
      }
      options: {
            }
    }
  }
    
  resource sqlContainerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
    parent: sqlDb 
    name: '${prefix}-orders'
    properties: {
      resource: {
        id: '${prefix}-orders'
        partitionKey: {
          paths: [
            '/id'
          ]
        }
      }
      options: {}
    }
  }
  
 
  
