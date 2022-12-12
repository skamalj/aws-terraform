resource "null_resource" "airflow" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  }  # Create service account for Airflow DBT pods
  provisioner "local-exec" {
    command = <<EOL
        kubectl create ns airflow;
        account_id=${local.account_id} ./dbt-glue-sa.sh | kubectl apply -f -;
        helm upgrade --install airflow airflow-stable/airflow \
        --namespace airflow --values override-baked-dags.yaml \
        --set externalDatabase.host=${module.aurora_rds.db_endpoint} \
        --set externalDatabase.password=${var.master_password};
    EOL
  }
  #provisioner "local-exec" {
  #  when    = destroy
  #  command = "helm uninstall airflow --namespace airflow"
  #}
  depends_on = [
    module.eks_cluster,
    null_resource.efs
  ]
}

resource "null_resource" "efs" {
  # Run this provisioner always
  triggers = {
    sa_def = file("./efs_sa.sh"),
    sc_def = file("./storageclass.sh")
  }  # Create service account for Airflow DBT pods
  provisioner "local-exec" {
    command = <<EOL
        kubectl create ns efs-ns;
        account_id=${local.account_id} ./efs_sa.sh | kubectl apply -f -;
        helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
        --namespace efs-ns \
        --set image.repository=602401143452.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/eks/aws-efs-csi-driver \
        --set controller.serviceAccount.create=false \
        --set controller.serviceAccount.name=efs-csi-controller-sa;
        airflow_efs_id=${aws_efs_file_system.airflow.id} ./storageclass.sh | kubectl apply -f -;
    EOL
  }
  #provisioner "local-exec" {
  #  when    = destroy
  #  command = "helm uninstall aws-efs-csi-driver --namespace efs-ns"
  #}
  depends_on = [
    module.eks_cluster
  ]
}

