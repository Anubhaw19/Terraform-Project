# creating a custom security group in our VPC for EC2 server (firewall)
resource "aws_security_group" "my_sg" {
  name        = "my-sg"
  vpc_id      = var.vpc_id
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
    values = [var.image_name] # regular expression to get the corresponding image name
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
  ami                         = data.aws_ami.latest-amazon-linux-image.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.my_sg.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true        # for public IP-address to the server
  key_name                    = aws_key_pair.ssh-key.key_name
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