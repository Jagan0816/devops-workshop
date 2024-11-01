
provider "aws" {
  region = "eu-north-1"  
}

resource "aws_instance" "demo-server" {
  ami = "ami-08eb150f611ca277f"
  instance_type = "t3.micro"
  key_name = "cicdproject1"
  //security_groups = ["demo-sg"]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  subnet_id = aws_subnet.dpp-public-subnet-01.id
  for_each = toset(["Jenkins-master","build-slave","ansible"])
  tags = {
    Name = "${each.key}"
  }
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id      = aws_vpc.dpp-vpc.id

  tags = {
    Name = "ssh-port"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh-access" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "jenkins-port-access" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

 
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc" "dpp-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    name = "dpp-vpc"
  } 
}

resource "aws_subnet" "dpp-public-subnet-01" {
  vpc_id = aws_vpc.dpp-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "eu-north-1a"
  tags = {
    Name = "dpp-public-subnet-01"
  }
}

resource "aws_internet_gateway" "dpp-igw" {
  vpc_id = aws_vpc.dpp-vpc.id
  tags = {
    Name = "dpp-igw"
  }
}

resource "aws_route_table" "dpp-public-rt" {
  vpc_id = aws_vpc.dpp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpp-igw.id
  }
}

resource "aws_route_table_association" "dpp-rta-public-subnet-01" {
  subnet_id = aws_subnet.dpp-public-subnet-01.id
  route_table_id = aws_route_table.dpp-public-rt.id
}

//resource "aws_route_table_association" "dpp-rta-public-subnet-02" {
  //subnet_id = aws_subnet.dpp-public-subnet-02.id
  //route_table_id = aws_route_table.dpp-public-rt.id
//}
