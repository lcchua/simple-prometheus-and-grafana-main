module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  name                        = var.ec2_name
  ami                         = data.aws_ami.aws_ami_data.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.azmi1-tf-sg-allow-ssh-http-https.id, aws_security_group.azmi1-tf-sg-allow-prometheus-grafana.id]
  subnet_id                   = data.aws_subnet.public_subnet_data.id
  associate_public_ip_address = true
  user_data                   = file("init-prometheus.sh")

  tags = {
    Name = var.ec2_name
  }
}