#  creating a subnet within VPC
resource "aws_subnet" "my_subnet-1" {
  vpc_id     = var.vpc_id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

#  creating an Internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

# creating a custom route table for internet traffic (needs internet gateway ID)
resource "aws_route_table" "my_route_table" {
  vpc_id = var.vpc_id

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
