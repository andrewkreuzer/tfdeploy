resource "aws_cloudwatch_log_group" "tfplan" {
  name = "/aws/codebuild/tfplan"
}

resource "aws_iam_role" "tfplan" {
  name = "tfplan-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tfplan" {
  role       = aws_iam_role.tfplan.name
  policy_arn = aws_iam_policy.tfplan.arn
}

resource "aws_iam_role_policy_attachment" "ReadOnly" {
  role       = aws_iam_role.tfplan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy" "tfplan" {
  name = "tfplan-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.tfplan.arn}*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.pipeline.arn}",
          "${aws_s3_bucket.pipeline.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_codebuild_project" "tfplan" {
  name           = "tfplan"
  queued_timeout = "5"

  service_role = aws_iam_role.tfplan.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.tfplan.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "codebuild/planspec.yml"
  }
}

