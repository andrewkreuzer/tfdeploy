data "aws_codestarconnections_connection" "me" {
  arn = "arn:aws:codestar-connections:us-east-2:146427984190:connection/c3a9a47e-a2eb-432c-b79a-b9c4ca5b0f3d"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "tf-deploy-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = "s3://playground.tf/tfdeploypipe/"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.me.arn
        FullRepositoryId = "tfdeploy"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name            = "Plan"
      category        = "Build"
      owner           = "AWS"
      provider        = "Codebuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["plan_output"]

      configuration = {
        ProjectName = "tfplan"
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name = "Approve"
      category = "Approval"
      owner = "AWS"
      provider = "Manaul"
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "Codebuild"
      input_artifacts = ["plan_output"]
      version         = "1"

      configuration = {
        ProjectName = "tfdeploy"
      }
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "deploy-tf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "deploy-tf"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::playground.tf",
        "arn:aws:s3:::playground.tf/tfdeploypipe/*",
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${data.aws_codestarconnections_connection.me.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
