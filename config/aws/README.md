# AWS

## AWS credentials

Deploying to a cloud provider requires configuration of the credentials to provide access to the services. 
For AWS this is commonly done by setting up a "credentials" file on the machine.

Another easier method is by setting it as environment variable in the terminal, which will have effect only in the current session.
```
$ export AWS_ACCESS_KEY_ID="<INSERT_AWS_ACCESS_KEY_ID_HERE>"
$ export AWS_SECRET_ACCESS_KEY="<INSERT_AWS_SECRET_ACCESS_KEY_HERE>"
```


## Credentials for optional docker environment

When running your project inside the provided docker environment, it is possible to set the "credentials" file following the instructions below. 
The file will be automatically mapped inside the container using docker volume binding, and these credentials will be used for the AWS operations/deployments.

### (Inside this folder)Create a folder ".aws" with "credentials" file inside, with the following content:
```
[default]
aws_access_key_id=DUMMYAWSACCESSKEYID
aws_secret_access_key=DUMMYAWSSECRETACCESSKEY

[aws-cloud]
aws_access_key_id=<INSERT_AWS_ACCESS_KEY_ID_HERE>
aws_secret_access_key=<INSERT_AWS_SECRET_ACCESS_KEY_HERE>
```
 
 - Change the 'credentials' file, putting the AWS credentials keys at the desired profile(like the proposed 'aws-cloud'). This profile can be selected by the deployment tool.
 - It is advised to let the 'default' profile with dummy credentials, preventing accidental usage of real credentials with aws-cli or others resources inside the container. 

 # CAUTION TO NOT COMMIT THE CREDENTIALS TO A VERSION CONTROL SYSTEM