locals {
  name                             = "personal-wireguard-server"
  region                           = "us-east-1"
  instance_type                    = "t3.micro"
  instance_profile                 = "AmazonSSMRoleForInstancesQuickSetup"
  ami_id                           = "ami-053b0d53c279acc90" # ubuntu 22.04 LTS
  existing_vpc_id                  = "vpc-0806a23b71bed215a"
  existing_subnet_id               = "subnet-032188003e1d4a81b"
  domain_zone_id                   = "Z05395351JNQ8CDRNKANI"
  wireguard_server_domain_endpoint = "wireguard.williseed.com"
}

module "wireguard_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-sg"
  description = "WireGuard Security Group"
  vpc_id      = local.existing_vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 51820
      to_port     = 51820
      protocol    = "udp"
      cidr_blocks = "136.32.26.184/32"
    }
  ]

  egress_rules = ["all-all"]

}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  name                        = local.name
  instance_type               = local.instance_type
  key_name                    = "${local.name}-ssh-key"
  ami                         = local.ami_id
  monitoring                  = false
  subnet_id                   = local.existing_subnet_id
  create_iam_instance_profile = false
  iam_instance_profile        = local.instance_profile
  vpc_security_group_ids      = [module.wireguard_sg.security_group_id]

  root_block_device = [{
    encrypted = true
  }]

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 8
    instance_metadata_tags      = "enabled"
  }

  user_data = templatefile("${path.module}/user_data.sh", {})
}

resource "aws_route53_record" "wireguard_record" {
  zone_id = local.domain_zone_id
  name    = local.wireguard_server_domain_endpoint
  type    = "A"
  ttl     = "300"
  records = [module.ec2.public_ip]
}
