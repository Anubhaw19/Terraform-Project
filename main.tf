provider "aws" {
    region = "us-east-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "env_prefix" {}
variable "avail_zone" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}

# creating a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
   tags = {
    Name = "${var.env_prefix}-vpc"
  }

}

#  creating a subnet within VPC
resource "aws_subnet" "my_subnet-1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

#  Creating an Internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

# creating a custom route table for internet traffic (needs internet gateway ID)
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}

# associating a subnet to the custom route table
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.my_subnet-1.id
  route_table_id = aws_route_table.my_route_table.id
}


# using default (main) route table instead of creating custom -

/*for that we just need to add a internet gateway, no need of associating any subnet,
 because all subnet within a VPC is associate to default (main) route table by Default*/  

# resource "aws_default_route_table" "main-rtb" {
#   default_route_table_id = aws_vpc.my_vpc.default_route_table_id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.my_igw.id
#   }
#   tags = {
#     Name = "${var.env_prefix}-default-rtb"
#   }
# }


# creating a custom security group in our VPC for EC2 server (firewall)
resource "aws_security_group" "my_sg" {
  name        = "my-sg"
  vpc_id      = aws_vpc.my_vpc.id
# incoming/inbound traffic rules
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
  }
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
#   outgoing/outbound traffic rules
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids  = []
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

/* using the default security group instead of creating a custom security group,
 and allowing inbound and outbound traffic*/
 
# resource "aws_default_security_group" "my_default_sg" {
#   vpc_id      = aws_vpc.my_vpc.id
# # incoming traffic rules
#   ingress {
#     from_port        = 22
#     to_port          = 22
#     protocol         = "tcp"
#     cidr_blocks      = [var.my_ip]
#   }
#   ingress {
#     from_port        = 8080
#     to_port          = 8080
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }
# #   outgoing traffic rules
#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     prefix_list_ids  = []
#   }

#   tags = {
#     Name = "${var.env_prefix}-default-sg"
#   }
# }

# selecting a recent AMI(Amazon Machine Image) based on filters
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"] # amazon
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] # regular expression to get the corresponding image name
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  
}
#  declaring our own public key for ssh instead of creating manually in AWS console
resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "my-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.my_subnet-1.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true # for public IP-address to the server
  key_name = aws_key_pair.ssh-key.key_name
  # key_name="server-key-pair" # key-pair name already created in AWS console

  # running initial script after starting the EC2-server
  # user_data = <<EOF
  #                 #!/bin/bash
  #                 sudo yum update -y && yum install -y docker
  #                 sudo systemctl start docker
  #                 sudo usermod -aG docker ec2-user
  #                 docker run -p 8080:80 nginx
  #               EOF
  user_data = file("entry-script.sh")
   
  tags = {
    Name = "${var.env_prefix}-server"
  }
}


output "EC2-server-public-IP" {
  value = aws_instance.my-server.public_ip
}