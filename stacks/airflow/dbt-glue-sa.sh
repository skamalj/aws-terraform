cat <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/name: dbt-glue
  name: dbt-glue
  namespace: airflow
  annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::${account_id}:role/DBTGlueRole
EOF
