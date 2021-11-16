# ---------------------------------------------------------------------------------------------------------------------
# EC2 INSTANCE CREATION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "foo" {
  ami           = "ami-0443305dabd4be2bc"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  #setting up the web server on the EC2 instance
  user_data     = <<-EOF
                  #!/bin/bash
                  sudo su
                  yum -y install httpd
                  echo "<p> My Instance! </p>" >> /var/www/html/index.html
                  sudo systemctl enable httpd
                  sudo systemctl start httpd
                  EOF

  vpc_security_group_ids = [
    aws_security_group.lambdaping-sg.id
  ]

  private_ip = "172.31.0.8"
  subnet_id  = aws_default_subnet.default_az1.id
}

#Create the key pair to connect to the EC2 instance
resource "aws_key_pair" "deployer" {
	key_name   = "deployer-key"
	public_key = file("~/.ssh/id_rsa.pub")
}

# ---------------------------------------------------------------------------------------------------------------------
# LOADING THE DEFAULT SUBNET INFORMATION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-2a"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_function" "lambda-get" {
  function_name = "nbo-tf-lambdaping"
  role          = aws_iam_role.role-lambda.arn
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"

  vpc_config {
      subnet_ids = [aws_default_subnet.default_az1.id]
      security_group_ids = [aws_security_group.lambdaping-sg.id]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM ROLE FOR THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "role-lambda" {
  name               = "nbolambdarole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
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

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUT
# ---------------------------------------------------------------------------------------------------------------------

output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.foo.public_ip
}

