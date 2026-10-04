// Production environment parameters.
// Full SKUs, zone-redundancy, geo-backup, private endpoints.
using './cell/main.bicep'
param cellName = 'prod-us1'
param location  = 'eastus2'
