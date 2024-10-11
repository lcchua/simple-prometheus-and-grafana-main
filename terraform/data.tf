# Get latest Amazon Linux 2023 ami

data "aws_ami" "aws_ami_data" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}

data "aws_subnet" "public_subnet_data" {
  filter {
    name   = "tag:Name"
    values = ["luqman-vpc-tf-module-public-us-east-1a"]

  }
}

data "aws_vpc" "vpc_data" {
  filter {
    name   = "tag:Name"
    values = ["luqman-vpc-tf-module"]
  }
}