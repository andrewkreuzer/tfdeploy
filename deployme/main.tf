terraform {
  backend "s3" {
    bucket  = "terraform.playground"
    key     = "tfdeployme/terraform.tfstate"
    region  = "us-east-2"
    profile = "personal"
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "personal"
}

data "archive_file" "deployme" {
  type        = "zip"
  output_path = "${path.module}/build/lambda.zip"
  source_dir = "${path.module}/src"
}

resource "aws_lambda_function" "deployme" {
  filename         = data.archive_file.deployme.output_path
  function_name    = "deployme"
  role             = aws_iam_role.deploymelambda.arn
  source_code_hash = data.archive_file.deployme.output_base64sha256
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"

  tags = {
    department = "tfdeployme"
  }
}

resource "aws_iam_role" "deploymelambda" {
  name = "deploymelambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  # inline_policy {
  #   name = "access_key_age"

  #   policy = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [
  #       {
  #         Action = [
  #           "iam:ListUsers",
  #           "iam:ListAccessKeys",
  #           "iam:UpdateAccessKey",
  #         ]
  #         Effect   = "Allow"
  #         Resource = "arn:aws:iam::456969868172:user/*"
  #       },
  #     ]
  #   })
  # }
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  role       = aws_iam_role.deploymelambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
