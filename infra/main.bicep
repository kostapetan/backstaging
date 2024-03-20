targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param backstageExists bool
@secure()
param backstageDefinition object
param radarDiscusionsExists bool
@secure()
param radarDiscusionsDefinition object

@description('Id of the user or app to assign application roles')
param principalId string

param ghAppId string
@secure()
param ghPrivateKey string
param ghOrg string
param ghRepo string

param pgSvcName string = 'postgres01'

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module monitoring './shared/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
  }
  scope: rg
}


module registry './shared/registry.bicep' = {
  name: 'registry'
  params: {
    location: location
    tags: tags
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
  }
  scope: rg
}

module appsEnv './shared/apps-env.bicep' = {
  name: 'apps-env'
  params: {
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
  scope: rg
}

module postgres './shared/container-app-service.bicep' = {
  name: 'postgres'
  scope: rg
  params: {
    name: pgSvcName
    location: location
    tags: tags
    environmentId: appsEnv.outputs.appEnvironmentId
    serviceType: 'postgres'
  }
}

module backstage './app/backstage.bicep' = {
  name: 'backstage'
  params: {
    name: '${abbrs.appContainerApps}backstage-${resourceToken}'
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}backstage-${resourceToken}'
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    containerAppsEnvironmentName: appsEnv.outputs.name
    containerRegistryName: registry.outputs.name
    exists: backstageExists
    appDefinition: backstageDefinition
    serviceId: postgres.outputs.serviceId
    radarDiscussionsUri: radarDiscusions.outputs.uri
  }
  scope: rg
}

module radarDiscusions './app/radar-discussions.bicep' = {
  name: 'radar-discusions'
  params: {
    name: '${abbrs.appContainerApps}radar-discus-${resourceToken}'
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}radar-discus-${resourceToken}'
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    containerAppsEnvironmentName: appsEnv.outputs.name
    containerRegistryName: registry.outputs.name
    exists: radarDiscusionsExists
    appDefinition: radarDiscusionsDefinition
    ghAppId: ghAppId
    ghPrivateKey: ghPrivateKey
    ghOrg: ghOrg
    ghRepo: ghRepo
  }
  scope: rg
}



output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.loginServer
