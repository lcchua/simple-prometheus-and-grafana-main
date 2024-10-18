terraform {
  backend "s3" {
    bucket = "sctp-ce7-tfstate"
    key    = "tf-pg-lcchua.tfstate"
    region = "us-east-1"
  }
  required_version = "~> 1.9.0"
}