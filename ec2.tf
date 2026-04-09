# --- PART 1: THE FIREWALL ---
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # --- ADD THIS HTTP RULE ---
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "allow-ssh-sg" }
}

# --- PART 2: THE KEY PAIR ---
resource "tls_private_key" "devops_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "devops-lab-key"
  public_key = tls_private_key.devops_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.devops_key.private_key_pem
  filename        = "devops-lab-key.pem"
  file_permission = "0400"
}

# --- PART 3: THE SERVER ---
resource "aws_instance" "devops_server" {
  ami           = "ami-06018068a18569ff2" # Amazon Linux 2023 Singapore
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_1.id

  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  user_data = <<-EOF
#!/bin/bash
# Using DNF because this is Amazon Linux
dnf update -y
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Pull and run Nginx
docker run -d -p 80:80 --name web-server nginx
EOF

  tags = { Name = "devops-lab-server" }
}
