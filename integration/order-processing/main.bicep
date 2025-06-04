param apiName string
param apiDisplayName string
param apiRevision string
param apiPath string
param apiSummary string
param apiDescription string

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: 'integrate-2025-apim'
}

resource apimProduct 'Microsoft.ApiManagement/service/products@2024-06-01-preview' = {
  name: 'e-commerce'
  parent: apim
  properties: {
    approvalRequired: true
    description: 'E-Commerce'
    displayName: 'E-Commerce'
    subscriptionRequired: true
    state: 'published'
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: apim
  name: apiName
  properties: {
    displayName: apiDisplayName
    description: apiDescription
    apiRevision: apiRevision
    subscriptionRequired: false
    path: apiPath
    protocols: [
      'https'
    ]
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
      openidAuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'subscription-key'
    }
    isCurrent: true
    format: 'openapi+json'
    value: loadTextContent('order-api.openapi.json')
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: api
  properties: {
    format: 'rawxml'
    value: loadTextContent('policy.xml')
  }
}

resource apimProductAPI 'Microsoft.ApiManagement/service/products/apiLinks@2024-06-01-preview' = {
  parent: apimProduct
  name: '${apiName}-e-commerce'
  properties: {
    apiId: api.id
  }
}

resource apic 'Microsoft.ApiCenter/services@2024-06-01-preview' existing = {
  name: 'integrate-2025'
}

resource apicWorkspace 'Microsoft.ApiCenter/services/workspaces@2024-06-01-preview' existing = {
  parent: apic
  name: 'default'
}

resource apicEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apicWorkspace
  name: 'dev-environment'
  properties: {
    title: 'dev environment'
    kind: 'development'
    server: {
      type: 'azure-api-management'
      managementPortalUri: [
        'https://integrate-2025-apim.azure-api.net'
      ]
    }
    onboarding: {
      developerPortalUri: [
        'https://integrate-2025-apim.developer.azure-api.net'
      ]
    }
    customProperties: {}
  }
}

resource apicAPI 'Microsoft.ApiCenter/services/workspaces/apis@2024-06-01-preview' = {
  parent: apicWorkspace
  name: apiName
  properties: {
    title: apiDisplayName
    summary: apiSummary
    description: apiDescription
    kind: 'REST'
    termsOfService: {
      url: 'https://aka.ms/apicenter-samples-api-termsofservice-link'
    }
    license: {
      name: 'MIT'
      url: 'https://aka.ms/apicenter-samples-api-license-link'
    }
    externalDocumentation: [
      {
        description: 'API Documentation'
        url: 'https://aka.ms/apicenter-samples-api-documentation-link'
      }
    ]
    contacts: [
      {
        name: 'John Doe'
        email: 'john.doe@example.com'
      }
    ]
    customProperties: {}
  }
}

resource apicAPIVersion 'Microsoft.ApiCenter/services/workspaces/apis/versions@2024-06-01-preview' = {
  parent: apicAPI
  name: '1-0-0'
  properties: {
    title: '1-0-0'
    lifecycleStage: 'development'
  }
}

resource apicAPIDefinition 'Microsoft.ApiCenter/services/workspaces/apis/versions/definitions@2024-06-01-preview' = {
  parent: apicAPIVersion
  name: 'default'
  properties: {
    description: 'default'
    title: 'default'
  }
}

resource apiDeployment 'Microsoft.ApiCenter/services/workspaces/apis/deployments@2024-06-01-preview' = {
  parent: apicAPI
  name: 'apideployment'
  properties: {
    description: 'apideployment'
    title: 'apideployment'
    environmentId: '/workspaces/default/environments/${apicEnvironment.name}'
    definitionId: '/workspaces/default/apis/${apicAPI.name}/versions/${apicAPIVersion.name}/definitions/${apicAPIDefinition.name}'
    state: 'active'
    server: {
      runtimeUri: [
        apim.properties.gatewayUrl
      ]
    }
  }
}
