output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.devops_server.public_ip
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}
