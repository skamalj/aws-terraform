## Create airflow on EKS

### Add required chart repos
* helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
* helm repo add airflow-stable https://airflow-helm.github.io/charts
* helm repo add karpenter https://charts.karpenter.sh 
* helm repo add eks https://aws.github.io/eks-charts

* Update required values in `values.auto.tfvars`. 
* Set DB password

```
export TF_VAR_master_password=<password>
``` 
* Update dags.gitsync.repo to your dag repository in override,yaml 
* Apply tenplate

```
terraform apply 
```
