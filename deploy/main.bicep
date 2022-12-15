@description('the region of deployment')
param location string = resourceGroup().location

@description('The type of environment, this must be nonprod or prod.')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string

@description('unique suffix for resources')
@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

var appServiceAppName = 'toy-website${resourceNameSuffix}'
var appServicePlanName = 'toy-website-plan'
var toyManualsStorageAccountName = 'toyweb${resourceNameSuffix}'

var environmentConfigurationMap = {
  nonprod: {
    appServicePlan: {
      sku: {
        name: 'F1'
        capacity: 1
      }
    }
    toyManualsStorageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
  }
  prod: {
    appServicePlan: {
      sku: {
        name: 'S1'
        capacity: 2
      }
    }
    toyManualsStorageAccount: {
      sku: {
        name: 'Standard_ZRS3'
      }
    }
  }
}

var toyManualsStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${toyManualsStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${toyManualsStorageAccount.listKeys().keys[0].value}'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  sku: environmentConfigurationMap[environmentType].appServicePlan.sku
}

resource appServiceApp 'Microsoft.Web/sites@2021-01-15' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'ToyManualsStorageAccountConnectionString'
          value: toyManualsStorageAccountConnectionString
        }
      ]
    }
  }
}

resource toyManualsStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: toyManualsStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: environmentConfigurationMap[environmentType].toyManualsStorageAccount.sku
}





