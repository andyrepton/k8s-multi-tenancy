variable "clustername" {}

# Replace these with your api key/secret key/api url
provider "aws" {
  access_key = "${replace("${file("~/.terraform/aws_sbp_access_key")}", "\n", "")}"
  secret_key = "${replace("${file("~/.terraform/aws_sbp_secret_key")}", "\n", "")}"
  region = "eu-west-1"
}

variable "keyname" { default = "bootstrap" }

variable "source_cidr" { }
variable "master_url" { }

variable "aws_region" {
  description = "AWS region to launch servers"
  default = "eu-west-1"
}
variable "aws_avzone" {
  description = "AWS availability zone for the subnet"
  default = "eu-west-1a"
}

variable "counts" {
  default = {
    vpcs = "1"
    subnets = "1"
    workers = "1"
  }
}

# worker settings
variable "worker-ami" {
  description = "CoreOS-stable-1068.6.0"
  default = "ami-7292f401"
}

variable "worker-instance-type" {
  default = "t2.small"
}

variable "binaries" {
  default = {
    kube-apiserver = "https://storage.googleapis.com/kubernetes-release/release/v1.3.0/bin/linux/amd64/kube-apiserver"
    kube-controller-manager = "https://storage.googleapis.com/kubernetes-release/release/v1.3.0/bin/linux/amd64/kube-controller-manager"
    kube-scheduler = "https://storage.googleapis.com/kubernetes-release/release/v1.3.0/bin/linux/amd64/kube-scheduler"
    kube-proxy = "https://storage.googleapis.com/kubernetes-release/release/v1.3.0/bin/linux/amd64/kube-proxy"
    kube-kubelet = "https://storage.googleapis.com/kubernetes-release/release/v1.3.0/bin/linux/amd64/kubelet"
  }
}
