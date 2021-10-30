# terraform-template

This repository intends to provide templates for terraform, using best practices and structure examples for future projects.

<br/><br/><br/>

## Tools

<br/>

# [Terraform](https://www.terraform.io) 

<a href="https://www.terraform.io"><img src="https://www.pinclipart.com/picdir/big/519-5197888_terraform-terraform-icon-png-clipart.png" align="right" height="100px" width="auto"/></a>
Infrastructure as Code tool that helps creation on multiple clouds.

Worked providers
- AWS
- <s>Azure</s>
- <s>Google Cloud</s>

<br/>

# [TODO: Terragrunt](https://terragrunt.gruntwork.io/) 

<a href="https://terragrunt.gruntwork.io/"><img src="https://aws1.discourse-cdn.com/standard11/uploads/gruntwork/original/1X/451c24614aece67849fd62d0432d77ecd00735c6.png" align="right" height="75px" width="auto"/></a>
Terraform wrapper, providing extra dynamicity and tools.

<br/>

# [Docker](https://www.docker.com/) as development environment


<a href="https://www.docker.com/"><img src="https://www.zadara.com/wp-content/uploads/docker.png" title="Docker" align="right" height="75px" width="auto"/></a>

Lightweight container for local development, with everything installed out of the box with additional tools for enhanced experience. *Check `Dockerfile` and `docker-compose.yml`*

Providers configuration could be done for all projects automatically(using docker volumes mapping), which would avoid the necessity of making the configuration in the host machine. *Config files and instructions at `/config/`*

Use  `Makefile` to set easly up containers and start terminal shell.

<br/><br/><br/>

---
## Main commands handbook
```
 - terraform init                                                        : init project, getting provider packages and importing modules

 - terraform plan                                                        : view infrastructure changes to be applied on deploy
 - terraform apply                                                       : deploy infrastructure on the provider
 - terraform destroy                                                     : remove infrastructure from the provider
    - ... --target <resource>                        : flag to select a single resource to be affected by the command
    - ... --var-file "<file>.tfvars"                 : flag to select a variable assignment file (defaults to terraform.tfvars)

 - terraform show                                                        : visualize information about the current deployed infrastructure
 - terraform output                                                      : view generated outputs from deploy

 - terraform workspace <subcommand>                                      : manage workspaces for managing different enviroments("terraform workspaces -help" for descriptions)
```
Unusual commands:
```
 - terraform state <subcommand>                                          : advanced infrastructure state management("terraform state -help" for descriptions)
   - ... list                                       : subcommand to visualize state resources
   - ... mv <source_resource> <updated_resource>    : subcommand to update a resource without destroy/recreate process(e.g.: renaming a resource)[CAUTION]
   - ... pull                                       : subcommand to fetch remote state(e.g.: for visualization)
   - ... rm <resource>                              : subcommand to remove resource only from state without destroying it
 - terraform import <create_resource_definition> <existing_resource_id>  : import an existing resource into a created terraform representation
 - terraform taint <resource>                                             : mark the resource as tainted, forcing the recreation on the next apply
 - terraform graph | dot -Tsvg > graph.svg                               : generate graph.svg image representation for infrastructure
```

Terraform generates a .tfstate file, which is very important because it uses it to keep track of current infrastructure and future changes, losing them cause sync problems with the real infrastructure and major problems. 
Use remote backends to store state, it protects sensible information and keep track of the deployed infrastructure. The backend must have as many protections as possible.


<br/><br/><br/>

---
## Multiple infrastructures and environments:

A very simple approach could be to duplicate projects files in different paths to ensure enviroment segregation (e.g: projA/dev/... projA/prod/...). Not recommended because it would result in unnecessary code duplication. A better solution is to use workspaces.

For a single backend approach, having multiple workspaces with names composed by multiple different values(project name and environment for example) would generate multiple state files and guarantee isolated environments. This way, an organized strategy to manage project and environment specific configurations would be to use multiple .tfvars files with parameters for each specific infrastructure. 

This approach requires close attention to select the correct desired workspace to run the terraform operations, as well as selecting the correct .tfvars file to apply the correct configuration on the selected workspace(infrastructure). To reduce human error, it's useful to create .tfvars definition files with names as <workspace_name>.tfvars to keep track of which infrastructure the config file bellongs to as well of the existant infrastructures environemnts for the project.

Summarizing the ideas of this topic for a centralized common backend(like a single s3 bucket), a common workflow example would be:

- Create the workspace, for example:
  
`Attention: unique name formated as something like {NAME}-{ENVIRONMENT} as it is simple and provides the information needed to specify the infrastructure with no naming conflicts`
```
   $ terraform workspace new infrastruture-example-dev
```

<br/>

- Or select it if already exists:
```
   $ terraform workspace select infrastruture-example-dev
```

<br/>

- Create and config the <workspace_name>.tfvars file
```
  > infrastruture-example-dev.tfvars
```
This file would parametrize different variable values for the different infrastructure's projects/environments.

It's even possible to use multiple accounts, the credentials profile could be parametrized using variables.

<br/>

- Run terraform operations, selecting the correct workspace config file:
```
   $ terraform apply --var-file $(terraform workspace show).tfvars
```
This way, the changes to the current workspace will be always applied using it's correspondent file.

<br/>

This workspace naming convention schema is to work around terraform limitation on allowing dynamic backend configurations, they cannot use any variable to customize the working backend and names must not conflict. Working with multiple different backends wouldn't require any attention to the workspace name at all. 

For multiple backends, it would be required to have the configuration modified for each project individually. Because this is not a scalable solution, there are other tools that can help make terraform configurations more dynamic, like Terragrunt:
- TODO

<br/><br/><br/>

---
### Notes:

Usually the project structure is modularized to be splitted in multiple atomic structures and glued together with data sources. This way, it becomes more modular and scalable, gets reduced blast radius for modifications and explicit separation of concerns. 

Naturally the base resources are deployed first, but it's a good idea to document the deployment order and how the infrastructures relate to each other as this may be a critical information and vary a lot.


<br/><br/><br/>

---
# Projects

Templates
 - _base                                                                               : base generic templates with a monorepo approach
    - complex-multifolder                                                                    : Not recommended, but workable, structure for projects
    - [complex-workspaces](./providers/aws/templates/_base/complex-workspaces/README.md)     : Recommended project structure using workspaces and single backend(s3)

Examples
 - [monorepo](./providers/aws/examples/monorepo/README.md)                                   : Complete example of a monorepo project, implementing few applications(ECS, Pipeline)
 - [web-fixed](./providers/aws/examples/web-fixed/README.md)                                 : Very simple example of web application structure with bastion access




<br/><br/><br/><br/><br/>
// TODO:    terraform with localhost(?)
//          visualization tools for infrastructure(?)
//          search more tools for terraform(?) - terragrunt

//          use official modules https://registry.terraform.io/browse/modules
//          enhance template and examples with terraform native functions and functionalities(test with "terraform console")
