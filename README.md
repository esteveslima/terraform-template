# terraform-template


### Main commands handbook
```
 - 'terraform init'                     : init project and get provider packages

 - 'terraform plan'                             : view infrastructure changes to be applied on deploy
 - 'terraform apply'                            : deploy infrastructure on the provider
 - 'terraform destroy'                          : remove infrastructure from the provider
    - '... -target <resource>'                  : flag to select a single resource to be affected by the command
    - '... -var-file "<file>.tfvars"'           : flag to select a variable assignment file (defaults to terraform.tfvars)

 - 'terraform show'                             : visualize information about the current deployed infrastructure
 - 'terraform state <subcommand>'               : visualize advanced information about the state of the infrastructure
 - 'terraform output'                           : view generated outputs from deploy
 - 'terraform graph | dot -Tsvg > graph.svg'    : generate graph image representation for infrastructure
```
PS: Generated .tfstate files are important to keep track of changes, losing them may cause sync problems. Use a backend for production environments.


<br/><br/><br/><br/><br/>
// TODO:    terraform with localhost
//          visualization tools for infrastructure(?)
//          search more tools for terraform(?)

//          workspaces
//          "monorepo"?
//          https://www.terraform.io/docs/cli/commands/graph.html
//          local-exec and remote-exec
//          data sources
//          s3 backend with mfa(?)
//          use official modules https://registry.terraform.io/browse/modules
//          enhance template and examples with terraform native functions and functionalities(test with "terraform console")
