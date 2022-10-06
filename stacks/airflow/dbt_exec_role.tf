data "aws_iam_policy_document" "dbt_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_cluster.oidc_cluster_issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:airflow:dbt-glue"]
    }
    principals {
      identifiers = [local.oidc_arb]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "dbt_glue_policy" {
    name = "DBTGluePolicy"
    policy = file("dbt_glue_policy.json")
}

module "dbt_glue_role" {
  source = "../../modules/iam_role"
  name = "DBTGlueRole"
  policies = ["DBTGluePolicy"]
  assume_role_policy = data.aws_iam_policy_document.dbt_assume_role_policy.json
  depends_on = [
    aws_iam_policy.dbt_glue_policy
  ]
}

