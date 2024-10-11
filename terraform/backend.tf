terraform {
  backend "s3" {
    bucket = "sctp-ce7-tfstate"
    key    = "terraform-ex-pro-graf-azmi1.tfstate" #Change the value of this to <your suggested name>.tfstate for  example
    region = "us-east-1"
  }
  required_version = "~> 1.9.5"
}