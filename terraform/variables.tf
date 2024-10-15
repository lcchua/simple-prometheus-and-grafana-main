variable "sg_name" {
  description = "The SG Name to create SG with"
  type        = string
  default     = "lcchua-tf-sg-allow-ssh-http-https"
}

variable "sg_name2" {
  description = "The SG Name to create SG with"
  type        = string
  default     = "lcchua-tf-sg-allow-prometheus-grafana"
}

variable "ec2_name" {
  description = "Name of EC2"
  type        = string
  default     = "lcchua-ec2-prometheus-grafana" # Replace with your preferred EC2 Instance Name 
}

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of EC2 Key Pair"
  type        = string
  default     = "lcchua-useast1-20072024" # Replace with your own key pair name (without .pem extension) that you have downloaded from AWS console previously
}