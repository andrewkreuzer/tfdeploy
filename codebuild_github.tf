resource "aws_cloudwatch_log_group" "githubplan" {
  name = "/aws/codebuild/githubplan"
}

resource "aws_iam_role" "githubplan" {
  name = "githubplan-role"

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

resource "aws_iam_role_policy_attachment" "githubplan" {
  role       = aws_iam_role.githubplan.name
  policy_arn = aws_iam_policy.githubplan.arn
}

resource "aws_iam_role_policy_attachment" "GHReadOnly" {
  role       = aws_iam_role.githubplan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy" "githubplan" {
  name = "githubplan-policy"

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
        Resource = "${aws_cloudwatch_log_group.githubplan.arn}*"
      },
    ]
  })
}

resource "aws_codebuild_project" "githubplan" {
  name           = "githubplan"
  queued_timeout = "5"

  service_role = aws_iam_role.githubplan.arn

  artifacts {
    type = "NO_ARTIFACTS"
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
      group_name = aws_cloudwatch_log_group.githubplan.name
    }
  }

  source_version = "main"
  source {
    type            = "GITHUB"
    location        = "https://github.com/andrewkreuzer/tfdeploy.git"
    git_clone_depth = 1
    buildspec       = "codebuild/planspec.yml"
  }
}

resource "aws_codebuild_webhook" "githubplan" {
  project_name = aws_codebuild_project.githubplan.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED, PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED"
    }

    filter {
      type    = "COMMIT_MESSAGE"
      pattern = ".*\\[Run Plan\\].*"

    }

    filter {
      type                    = "HEAD_REF"
      pattern                 = "master"
      exclude_matched_pattern = true
    }
  }
}
