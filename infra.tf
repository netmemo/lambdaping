#ssh -i "~/.ssh/id_rsa" ec2-user@3.19.244.192

#resource "aws_eip" "bar" {
#  vpc = true
#  instance                  = aws_instance.foo.id
#  associate_with_private_ip = "172.31.0.8"
#}

resource "aws_instance" "foo" {
  ami           = "ami-0443305dabd4be2bc"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  user_data     = <<-EOF
                  #!/bin/bash
                  sudo su
                  yum -y install httpd
                  echo "<p> My Instance! </p>" >> /var/www/html/index.html
                  sudo systemctl enable httpd
                  sudo systemctl start httpd
                  EOF

  #tags = {
  #  Name = "nbo-instance"
  #}

  vpc_security_group_ids = [
    aws_security_group.ubuntu.id
  ]

  private_ip = "172.31.0.8"
  subnet_id  = aws_default_subnet.default_az1.id
}


resource "aws_key_pair" "deployer" {
	key_name   = "deployer-key"
	public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "ubuntu" {
  name        = "vm-sg-1"
  description = "Allow HTTP, HTTPS and SSH traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.foo.public_ip
}
