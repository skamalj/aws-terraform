## Create Hasura instance 
```
export TF_VAR_master_password=<password>
terraform apply -auto-approve
```
Open nlb_dns endpoint in browser

```
#set($userGroups = $context.authorizer.claims['cognito:groups'])
#if($userGroups.contains("admin"))
  #set($context.requestOverride.header.X-Hasura-Role = "admin")
#else
   #set($context.requestOverride.header.X-Hasura-Role = "Reader")    
#end
{
"query": "query { profiles {id, name }}"
}
```

```
{
"query": "query { profiles_by_pk(id: $input.params("id")) {id,name}}"
}
```