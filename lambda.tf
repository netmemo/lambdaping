
resource "aws_security_group" "sglambda" {
  name        = "ubuntu-security-group"
  description = "Allow HTTP, HTTPS and SSH traffic"

  ingress {
    description = "ALL_ICMP"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_function" "lambda-get" {
  function_name = "nbo-tf-helloword-3"
  role          = aws_iam_role.role-lambda.arn
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"

  vpc_config {
      subnet_ids = [aws_default_subnet.default_az1.id]
      security_group_ids = [aws_security_group.sglambda.id]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM ROLE FOR THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "role-lambda" {
  name               = "nbolambdarole"
  assume_role_policy = data.aws_iam_policy_document.lambda_role.json
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "vpcpolicy" {
 name = "AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "role-policy-attach" {
  role       = aws_iam_role.role-lambda.name
  policy_arn = data.aws_iam_policy.vpcpolicy.arn
}

