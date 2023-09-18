## Pre-requisites
*  Install helm, kubectl, terraform, kustomize
*  add following charts for LB and karpenter deployment
*  Download ALB and karpenter images and push to ECR. Then update respective commands in null_resource file 
```  
helm repo add karpenter https://charts.karpenter.sh 

helm repo add eks https://aws.github.io/eks-charts
```
## Create Cluster
First command creates fully private cluster, second one enables public endpoint for cluster. 
Nodes are still private with no access to internet
```
terraform init -backend-config="bucket=<your s3 bucket for state>"
terraform apply
terraform apply -var="endpoint_public_access=true"
```
## Enable Custom Networking - POD Subnets


Update the addon version based on this [documentation](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html)

``````
 aws eks create-addon --cluster-name <clustername> --addon-name vpc-cni --addon-version v1.15.0-eksbuild.2 --service-account-role-arn arn:aws:iam::<account number>:role/AmazonEKSVPCCNIRole
```

### Enable CNI custom networking on controller
```
kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
```
### Apply ENI configuration to each zone, specifying pod subnet per zone
```
terraform output pod_subnets | grep  "=" | cut -d '"' -f 2 > custom_pod_cni/subnets.env
kustomize build custom_pod_cni/ | kubectl apply -f - 
```
### Update CNI so that it picks corresponding ENIConfig for each zone. Since subnets are zonal, this ensures that in case of multizone cluster
### pods are assigned IPs from corresponding zonal subnet
```
kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
```
### Now recreate the node group. Only new node groups will apply this change
```
terraform apply -var="endpoint_public_access=true" -replace=module.eks_node_group_1.aws_eks_node_group.eks_ng
```
## Deploy ALB Controller (This is deployed by default, instructions are for reference)

* Replace your account id in the service account yaml file (in annotation)
* Use helm "upgrade" instead of "install"  after first run.
* When running on fargate, instance metadata is not available hence last two options - region and vpcid - are required
```
kubectl apply -f aws-load-balancer-controller-service-account.yaml

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${module.eks_private_cluster.eks.name} \
  --set serviceAccount.create=false \
  --set image.repository=602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon/aws-load-balancer-controller \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set enableShield=false \
  --set enableWaf=false \
  --set enableWafv2=false \
  --set region=ap-south-1 \
  --set vpcId=vpc-0d82c0a2fbdee4b5b
```

## Install Karpenter (This is deployed by default, instructions are for reference)
* You must download and push images **karpenter_controller** and **karpenter_webhook** to your ECR repository and provide the images in 
command below. 

```
helm upgrade --install --namespace karpenter --create-namespace \
  karpenter karpenter/karpenter \
  --version v0.9.1 \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::715267777840:role/karpenter-controller-${module.eks_private_cluster.eks.name} \
  --set clusterName=${module.eks_private_cluster.eks.name} \
  --set clusterEndpoint=https://07B972F903C2C6BCB4414611A2431306.gr7.ap-south-1.eks.amazonaws.com \
  --set aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${module.eks_private_cluster.eks.name} \
  --set controller.image=715267777840.dkr.ecr.ap-south-1.amazonaws.com/karpenter_controller:v0.9.1 \
  --set webhook.image=715267777840.dkr.ecr.ap-south-1.amazonaws.com/karpenter_webhook:v0.9.1 \
  --wait # for the defaulting webhook to install before creating a Provisioner
```
* Karpenter nodes can be deleted using kubectl, it makes sure that node is cordoned and ten deleted.
* Terraform destroy leaves out karpenter nodes.  Since TF is not aware of these (inlike node groups) and Karpenter pod goes unscheduled. 