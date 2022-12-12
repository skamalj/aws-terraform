This repository is for this [blog post](https://www.kamalsblog.com/2022/12/build-scalable-data-api-with-graphql-on-ecs.html)
## Create Hasura instance 
```
export TF_VAR_master_password=<password>
terraform init -backend-config="bucket=<your s3 bucket for state>"
terraform apply -auto-approve
```
## Create Sample Data
* Open nlb_dns (public) endpoint in browser and create table name 'profiles' with columns as described below
```
profiles (
  id SERIAL PRIMARY KEY, -- serial -> auto-incrementing integer
  name TEXT
)
```
* Create few rows in the table from UI

## Configure API Gateway

* Create VPC Link for internal NLB  (Select Rest API option on screen)
  * This can take upto 5 minutes  
* Create API -> Add resource "profile" -> Add method "GET"
  * In the "Integration Request" :-
    * Select Type as VPC_LINK and Method "POST"
    * Endpoint URL = https://<internal LB dns>/v1/graphql
    * In the mapping, set passthrough to "Never", Content-type to "application/json" and then paste following content in text pane
    ```
    {
      "query": "query { profiles {id, name }}"
    }
    ```
* Publish API
* Access API endpoint <API endpoint>/profile
  * This should return both rows
* Create /profile/(id) resource with "GET" method. In this case add belwo mapping template
  ```
  {
    "query": "query { profiles_by_pk(id: $input.params("id")) {id,name}}"
  }
  ```
### This Mapping Template can be added to any or both of the API endpoints to enable RBAC.

This is described in the [blog post](https://www.kamalsblog.com/2022/12/implement-rbac-for-data-apis-using-aws-cognito-apigw-graphql.html)

```
#set($userGroups = $context.authorizer.claims['cognito:groups'])
#if($userGroups.contains("Reader"))
  #set($context.requestOverride.header.X-Hasura-Role = "Reader")
#else
   #set($context.requestOverride.header.X-Hasura-Role = "Public")    
#end

```
