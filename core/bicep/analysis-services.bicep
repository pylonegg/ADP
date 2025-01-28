param resourceLocation string
param analysisServicesName string


@description('Deploy Azure Analysis Services resource')
resource r_analysisServices 'Microsoft.AnalysisServices/servers@2017-08-01' = {
  name: analysisServicesName
  location: resourceLocation
  sku: {
    capacity: 1
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    asAdministrators: {
      members: [
        'chi@chiadiukwuoutlook.onmicrosoft.com'
      ]
    }
    ipV4FirewallSettings: {
      enablePowerBIService: true
      firewallRules: [
        {
          firewallRuleName: 'Rule1'
          rangeEnd: '255.255.255.255'
          rangeStart: '0.0.0.0'
        }
      ]
    }
    managedMode: 1
    querypoolConnectionMode: 'All'
    serverMonitorMode: 1
    sku: {
      capacity: 1
      name: 'S0'
      tier: 'Standard'
    }
  }
}
