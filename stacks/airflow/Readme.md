## Create airflow on EKS

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
