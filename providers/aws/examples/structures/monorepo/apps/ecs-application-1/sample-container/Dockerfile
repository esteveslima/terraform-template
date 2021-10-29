FROM nginxdemos/hello

# Use this replace command to update image and try to push manually again to verify the changes(required to update the service to force new deployment)

# # Modify NGINX html replacing "Hello World" title text to update image
# RUN sed -i -e 's/Hello\ World/Replaced\ text/g' /usr/share/nginx/html/index.html

EXPOSE 80





# To push the app image to ECR manually follow the steps below:
# 1- Login:
# docker login --username AWS --password $(aws ecr get-login-password --region <REGION> --profile <PROFILE>) <ECR_URI>
# 2- Build:
# docker build -t <ECR_REPOSITORY_NAME> .
# 3- Tag:
# docker tag <ECR_REPOSITORY_NAME>:latest <ECR_URI>:latest
# 4- Push:
# docker push <ECR_URI>:latest
