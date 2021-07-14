# terraform-template



### Main commands handbook
```
 - 'terraform init'                                                        : init project, getting provider packages and importing modules

 - 'terraform plan'                                                        : view infrastructure changes to be applied on deploy
 - 'terraform apply'                                                       : deploy infrastructure on the provider
 - 'terraform destroy'                                                     : remove infrastructure from the provider
    - '... -target <resource>'                        : flag to select a single resource to be affected by the command
    - '... -var-file "<file>.tfvars"'                 : flag to select a variable assignment file (defaults to terraform.tfvars)

 - 'terraform show'                                                        : visualize information about the current deployed infrastructure
 - 'terraform output'                                                      : view generated outputs from deploy

 - 'terraform workspace <subcommand>'                                      : manage workspaces for managing different enviroments("terraform workspaces -help" for descriptions)

 unusual commands:
 - 'terraform graph | dot -Tsvg > graph.svg'                               : generate graph.svg image representation for infrastructure
 - 'terraform import <create_resource_definition> <existing_resource_id>'  : import an existing resource into a created terraform representation
 - 'terraform state <subcommand>'                                          : advanced infrastructure state management("terraform state -help" for descriptions)
   - '... list'                                       : visualize state resources
   - '... mv <source_resource> <updated_resource>'    : update a resource without destroy/recreate process(e.g.: renaming a resource), use with caution
   - '... pull'                                       : fetch remote state(e.g.: for visualization)
   - '... rm <resource>'                              : remove resource only from state without destroying it
```

Generated .tfstate files are important to keep track of changes, losing them may cause sync problems. 
For real projects it is required to use remote backends to store state, due to it's transparency with sensible information in the file.

<br/><br/><br/>

### Managing multiple environments/stages:

For a single account one approach is to use multiple .tfvars files(to assign stage specific variables) with parametrized parameters alongside workspaces(to store different stage files). This would require to select the desired environment/stage workspace and then run the commands selecting the correspondent .tfvars file.

Another approach could be to duplicate projects files in different paths to ensure enviroment segregation (e.g: projA/dev/... projA/prod/...).

The first approach would use the same code but would require attention to not make a mistake using the wrong workspace, the second approach has more secure environment segregation but relies on code replication.

Finally, for multiple accounts, the credentials profile could be parametrized using variables.






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
