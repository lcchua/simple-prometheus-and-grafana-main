terraform {
  backend "s3" {
    bucket = "sctp-ce7-tfstate"
    key    = "tf-ex-pro-graf-lcchua.tfstate" #Change the value of this to <your suggested name>.tfstate for  example
    region = "us-east-1"
  }
  required_version = "~> 1.9.5"
}