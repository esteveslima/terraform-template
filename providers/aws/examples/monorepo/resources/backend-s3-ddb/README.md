### Only generates the backend, it doesn't require to monitor state

### Must be deployed before everything

### This project rely on the usage of this single s3 backend, changing this setting would require a review and adjustments on backend configurations and remote state data sources
- The workspaces must differ by name following the pattern: `[name]-[environment]`, this way there will be no name conflicts between different applications in different environments