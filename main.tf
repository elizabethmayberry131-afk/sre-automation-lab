# 1. Create the VPC (The private playground)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # Important for EKS later

  tags = {
    Name = "devops-lab-vpc"
  }
}

# 2. Create a Public Subnet (Where the EC2 will live for now)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # This makes it "Public"
  availability_zone       = "ap-southeast-1a"

  tags = {
    Name = "public-subnet-1"
  }
}

#2.1 create a different subnet
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1b"

  tags = {
    Name = "public-subnet-2"
  }
}

# 3. Create an Internet Gateway (The "Door" to the internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# 4. Create a Route Table (The "Map" for traffic)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Send all outgoing traffic to IGW
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. Associate Route Table with Subnet
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

#6 Get to CI/CD
resource "aws_ecr_repository" "devops_app_repo" {
  name                 = "devops-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.devops_app_repo.repository_url
}

#6.1 GitHub way

# --- THE NEW SECURITY BRIDGE FOR GITHUB ---
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:elizabethmayberry131-afk/sre-automation-lab:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}

terraform {
  backend "s3" {
    bucket  = "zhongyao-terraform-state-2026"
    key     = "devops-lab/terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }
}
