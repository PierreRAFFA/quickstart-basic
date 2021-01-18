# Laravel Quickstart - AWS - Fargate

## Technical Overview
 - Terraform >= 0.12
 - aws-cli/2.x
 - Docker
 - Docker Compose
 
## Commands

Command to run CI script  
```bash
./ops/scripts/ci.sh
```

Command to run CD script  
Please set AWS Access token before  
```bash
./ops/scripts/cd.sh
```

## Other
Dashboard created to track the number of page hits

## Improvements
 - Set limited permissions to `deployer` AWS user
 - Create a RDS in AWS instead of an embedded sqlite in the app image. 
 - Set LoadBalancer and Target group to scale the service and handle higher traffic
From my point of view, if you ask for assigning a public IP to the ECS instance, it means there is no need to have a load balancer  
( I can provide the resources to assign a load balancer to the ECS Service if need be)  
 - Remove .env file and set all env variables directly in Task Definition
 - Set Laravel APP_KEY in Secret Manager
 - Use custom  VPC instead
 - Use php:7.4-fpm-alpine to generate a lighter image

