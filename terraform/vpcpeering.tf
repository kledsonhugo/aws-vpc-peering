# VPC
resource "aws_vpc" "vpc10" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = "true"
    tags = {
        Name = "vpc10"
    }
}

resource "aws_vpc" "vpc20" {
    cidr_block           = "20.0.0.0/16"
    enable_dns_hostnames = "true"
    tags = {
        Name = "vpc20"
    }
}

# SUBNETS
resource "aws_subnet" "sn_vpc10_pub" {
    vpc_id                  = aws_vpc.vpc10.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "sn_vpc10"
    }
}

resource "aws_subnet" "sn_vpc20_priv" {
    vpc_id            = aws_vpc.vpc20.id
    cidr_block        = "20.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "sn_vpc20"
    }
}

# VPC PEERING
resource "aws_vpc_peering_connection" "vpc_peering" {
    peer_vpc_id   = aws_vpc.vpc20.id
    vpc_id        = aws_vpc.vpc10.id
    auto_accept   = true  
    tags = {
        Name = "vpc_peering"
    }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "igw_vpc10" {
    vpc_id = aws_vpc.vpc10.id
    tags = {
        Name = "igw_vpc10"
    }
}

# ROUTE TABLE
resource "aws_route_table" "rt_sn_vpc10_pub" {
    vpc_id = aws_vpc.vpc10.id
    route {
        cidr_block = "20.0.0.0/16"
        gateway_id = aws_vpc_peering_connection.vpc_peering.id
    }
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_vpc10.id
    }
    tags = {
        Name = "rt_sn_vpc10_pub"
    }
}

resource "aws_route_table" "rt_sn_vpc20_priv" {
    vpc_id = aws_vpc.vpc20.id
    route {
        cidr_block = "10.0.0.0/16"
        gateway_id = aws_vpc_peering_connection.vpc_peering.id
    }
    tags = {
        Name = "rt_sn_vpc20_priv"
    }
}

# SUBNET ASSOCIATION
resource "aws_route_table_association" "rt_sn_vpc10_pub_To_sn_vpc10_pub" {
  subnet_id      = aws_subnet.sn_vpc10_pub.id
  route_table_id = aws_route_table.rt_sn_vpc10_pub.id
}

resource "aws_route_table_association" "rt_sn_vpc20_priv_To_sn_vpc20_priv" {
  subnet_id      = aws_subnet.sn_vpc20_priv.id
  route_table_id = aws_route_table.rt_sn_vpc20_priv.id
}

# SECURITY GROUPS
resource "aws_security_group" "sg_ec2_vpc10_pub" {
    vpc_id = aws_vpc.vpc10.id
    egress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/16"]
    }
    ingress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = ["20.0.0.0/16"]
    }
    ingress {
        from_port   = "3389"
        to_port     = "3389"
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "sg_ec2_vpc10_pub"
    }
}

resource "aws_security_group" "sg_ec2_vpc20_priv" {
    vpc_id = aws_vpc.vpc20.id
    egress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/16"]
    }
    ingress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = ["20.0.0.0/16"]
    }
    tags = {
        Name = "sg_ec2_vpc20_priv"
    }
}

# EC2 INSTANCES
resource "aws_instance" "instance_sn_vpc10_pub" {
    ami                    = "ami-0e38fa17744b2f6a5"
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.sn_vpc10_pub.id
    vpc_security_group_ids = [aws_security_group.sg_ec2_vpc10_pub.id]
    key_name               = "vockey"
    tags = {
        Name = "instance_sn_vpc10_pub"
    }
}

resource "aws_instance" "instance_sn_vpc20_priv" {
    ami                    = "ami-0e38fa17744b2f6a5"
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.sn_vpc20_priv.id
    vpc_security_group_ids = [aws_security_group.sg_ec2_vpc20_priv.id]
    key_name               = "vockey"
    tags = {
        Name = "instance_sn_vpc20_priv"
    }
}