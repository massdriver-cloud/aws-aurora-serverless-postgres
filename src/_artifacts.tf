locals {
  data_authentication = {
    username = aws_rds_cluster.main.master_username
    password = aws_rds_cluster.main.master_password
    hostname = aws_rds_cluster.main.endpoint
    port     = aws_rds_cluster.main.port
  }
  data_infrastructure = {
    arn = aws_rds_cluster.main.arn
  }

  rdbms_specs = {
    engine         = "PostgreSQL"
    engine_version = aws_rds_cluster.main.engine_version
    version        = aws_rds_cluster.main.engine_version_actual
  }
}

resource "massdriver_artifact" "authentication" {
  field                = "authentication"
  provider_resource_id = aws_rds_cluster.main.arn
  name                 = "'Root' Postgres user credentials: ${aws_rds_cluster.main.cluster_identifier}"
  artifact = jsonencode(
    {
      data = {
        authentication = local.data_authentication
        infrastructure = local.data_infrastructure
        security       = {}
      }
      specs = {
        rdbms = local.rdbms_specs
      }
    }
  )
}
