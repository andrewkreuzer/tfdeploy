resource "aws_cloudwatch_log_group" "tfdeploy" {
  name = "/aws/codebuild/tfdeploy"
}

resource "aws_iam_role" "tfdeploy" {
  name = "tfdeploy-role"

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

resource "aws_iam_role_policy_attachment" "tfdeploy" {
  role       = aws_iam_role.tfdeploy.name
  policy_arn = aws_iam_policy.tfdeploy.arn
}

resource "aws_iam_policy" "tfdeploy" {
  name = "tfdeploy-policy"

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
        Resource = "${aws_cloudwatch_log_group.tfdeploy.arn}*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::playground.tf",
          "arn:aws:s3:::playground.tf/tfdeploypipe/*"
        ]
      },
    ]
  })
}

resource "aws_codebuild_project" "tfdeploy" {
  name           = "tfdeploy"
  queued_timeout = "5"

  service_role = aws_iam_role.tfdeploy.arn

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
      group_name = aws_cloudwatch_log_group.tfdeploy.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "codebuild/deployspec.yml"
  }
}

