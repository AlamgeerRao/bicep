param env string 
param vmNames array
param adminUsername string
param keyVaultName string
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


