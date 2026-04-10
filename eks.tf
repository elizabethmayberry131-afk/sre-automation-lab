module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "devops-lab-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  intra_subnets   = ["10.0.151.0/24", "10.0.152.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  # --- ADD THESE THREE LINES ---
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"          = 1
    "kubernetes.io/cluster/devops-lab-cluster" = "shared" # <-- MUST BE HERE
  }
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "devops-lab-cluster"
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # FIXED: This block is now INSIDE the EKS module
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  eks_managed_node_groups = {
    green = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Use 'small' as it's the closest to 'micro' but still works for EKS
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"

      # This forces AWS to use a fresh disk config 
      # and bypass the "Free Tier" default disk check
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            throughput            = 125
            delete_on_termination = true
          }
        }
      }

      # This removes any legacy Free Tier tags from the launch
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }
    }
  }
  enable_cluster_creator_admin_permissions = true
}
