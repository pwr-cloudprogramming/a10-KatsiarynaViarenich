terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.1"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0d7a109bf30624c99"
  instance_type = "t2.micro"
  tags = {
    Name      = "MyServerKVA5"
    Terraform = "true"
  }
}
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
  vpc_id      = module.my_vpc.vpc_id
  tags = {
    Name = "allow-ssh-http"
  }
}

module "my_vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "my-vpc-KVA5"
  cidr           = "10.0.0.0/16"
  azs            = ["us-east-1b"]
  public_subnets = ["10.0.101.0/24"]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8082
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_cognito_user_pool_client" "client" {
  name = "A10_game"

  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret     = false
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
}

resource "aws_cognito_user_pool" "pool" {
  name = "A10_game"
  alias_attributes = ["preferred_username"]

  username_configuration {
    case_sensitive = false
  }

  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject = "Your verification code"
    email_message = "Your verification code is {####}"
    sms_message = "Your verification code is {####}"
  }

  auto_verified_attributes = ["email"]
}

resource "local_file" "config_json" {
  content = jsonencode({
    region = "us-east-1"
    userPoolId = aws_cognito_user_pool.pool.id
    clientId   = aws_cognito_user_pool_client.client.id
  })
  filename = "${path.module}/frontend/frontend-client-react/src/config.json"
}


resource "aws_instance" "tf-web-server" {
  ami                         = "ami-080e1f13689e07408"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = module.my_vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = true
  user_data                   = file("run.sh")
  user_data_replace_on_change = true
  tags = {
    Name = "A5"
  }
  
  provisioner "file" {
    source      = "${path.module}/frontend/frontend-client-react/src/config.json"
    destination = "/home/ubuntu/config.json"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/environment/aws-lab.3/labsuser10.pem")
    host        = self.public_ip
  }
}
