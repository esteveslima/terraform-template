FROM nginxdemos/hello

EXPOSE 80

# After create the infrastructure, it's necessary to push the app image to ECR:
# 1- Login:
# docker login --username AWS --password $(aws ecr get-login-password --region <REGION> --profile <PROFILE>) <ECR_URI>
# 2- Build:
# docker build -t example_ecr_repository .
# 3- Tag:
# docker tag example_ecr_repository:latest <ECR_URI>:latest
# 4- Push:
# docker push <ECR_URI>:latest