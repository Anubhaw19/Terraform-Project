provider "aws" {
    region = "us-east-1"
}



# creating a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
   tags = {
    Name = "${var.env_prefix}-vpc"
  }

}

/* -SUBNET
   -Internet
   -Gateway 
   -Route table creation (custom/default)
   -Subnet association to custom route table
    moved to modules/subnet/main.tf */

  module "my-subnet" {
  source = "./modules/subnet" 
  subnet_cidr_block =  var.subnet_cidr_block
  env_prefix = var.env_prefix
  avail_zone = var.avail_zone
  vpc_id = aws_vpc.my_vpc.id
  }

  module "my-server" {
    source              = "./modules/webserver"
    vpc_id              = aws_vpc.my_vpc.id
    subnet_id           = module.my-subnet.subnet.id
    env_prefix          = var.env_prefix
    avail_zone          = var.avail_zone
    my_ip               =var.my_ip
    instance_type       = var.instance_type
    image_name          = var.image_name
    public_key_location = var.public_key_location
    
  }




