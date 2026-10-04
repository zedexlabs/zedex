// Staging environment parameters.
// Mid-tier SKUs; mirrors prod topology but reduced capacity.
using './cell/main.bicep'
param cellName = 'staging-us1'
param location  = 'eastus2'
