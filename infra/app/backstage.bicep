param name string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerRegistryName string
param containerAppsEnvironmentName string
param applicationInsightsName string
param exists bool
@secure()
param appDefinition object

var backstagePort = 7007
param serviceId string = ''
param radarDiscussionsUri string

var appSettingsArray = filter(array(appDefinition.settings), i => i.name != '')
var secrets = map(filter(appSettingsArray, i => i.?secret != null), i => {
  name: i.name
  value: i.value
  secretRef: i.?secretRef ?? take(replace(replace(toLower(i.name), '_', '-'), '.', '-'), 32)
})
var env = map(filter(appSettingsArray, i => i.?secret == null), i => {
  name: i.name
  value: i.value
})

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' existing = {
  name: containerAppsEnvironmentName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(subscription().id, resourceGroup().id, identity.id, 'acrPullRole')
  properties: {
    roleDefinitionId:  subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalType: 'ServicePrincipal'
    principalId: identity.properties.principalId
  }
}

module fetchLatestImage '../modules/fetch-container-image.bicep' = {
  name: '${name}-fetch-image'
  params: {
    exists: exists
    name: name
  }
}

resource app 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: name
  location: location
  tags: union(tags, {'azd-service-name':  'backstage' })
  dependsOn: [ acrPullRole ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${identity.id}': {} }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    
    configuration: {
      
      ingress:  {
        external: true
        targetPort: backstagePort
        transport: 'auto'
      }
      
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: identity.id
        }
      ]
      secrets: union([
      ],
      map(secrets, secret => {
        name: secret.secretRef
        value: secret.value
      }))
    }
    template: {
      serviceBinds: !empty(serviceId) ? [
        {
          serviceId: serviceId
        }
      ] : null
      
      containers: [
        {
          image: fetchLatestImage.outputs.?containers[?0].?image ?? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: 'main'
          env: union([
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
            {
              name: 'PORT'
              value: '80'
            }
            {
              name: 'APP_CONFIG_app_baseUrl'
              value:  'https://${name}.${containerAppsEnvironment.properties.defaultDomain}'
            }
            {
              name: 'APP_CONFIG_backend_baseUrl'
              value: 'https://${name}.${containerAppsEnvironment.properties.defaultDomain}'
            }
            {
              name: 'RADAR_FUNC_URL'
              value: '${radarDiscussionsUri}/discussions'
            }
          ],
          env,
          
          map(secrets, secret => {
            name: secret.name
            secretRef: secret.secretRef
          }))
          resources: {
            cpu: json('1.0')
            memory: '2.0Gi'
          }
          probes: [
            {
              failureThreshold: 5
              httpGet: {
                path: '/healthcheck'
                port: backstagePort
              }
              initialDelaySeconds: 60
              periodSeconds: 10
              timeoutSeconds: 3
              type: 'liveness'
            }
            {
              failureThreshold: 5
              httpGet: {
                path: '/healthcheck'
                port: backstagePort
              }
              initialDelaySeconds: 20
              periodSeconds: 10
              timeoutSeconds: 3
              type: 'startup'
            }
            {
              failureThreshold: 5
              httpGet: {
                path: '/healthcheck'
                port: backstagePort
              }
              initialDelaySeconds: 40
              periodSeconds: 10
              timeoutSeconds: 3
              type: 'readiness'
            }
          ]
        }
      ]
      
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
output name string = app.name
output uri string = 'https://${app.properties.configuration.ingress.fqdn}'
output id string = app.id
