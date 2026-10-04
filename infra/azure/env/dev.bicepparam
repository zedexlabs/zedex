// Development environment parameters.
// Low-SKU overrides: Basic Postgres, no zone-redundancy, minimal replicas.
using './cell/main.bicep'
param cellName = 'dev-us1'
param location  = 'eastus2'
