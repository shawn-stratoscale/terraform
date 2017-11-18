# Creating a VPC & Networking
resource "aws_vpc" "default" {
    cidr_block = "192.168.0.0/16"
    enable_dns_support = false
#    tags {
#        Name = "roche"
#     }
}

resource "aws_vpc" "rds" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
#    tags {
#        Name = "roche"
#     }
}

resource "aws_subnet" "subnet1"{
    cidr_block = "192.168.0.0/24"
    vpc_id = "${aws_vpc.default.id}"
    availability_zone = "us-west-1a"
}

resource "aws_subnet" "subnet2"{
    cidr_block = "10.0.0.0/24"
    vpc_id = "${aws_vpc.rds.id}"
    availability_zone = "us-west-1a"
}

resource "aws_subnet" "subnet3"{
    cidr_block = "10.0.1.0/24"
    vpc_id = "${aws_vpc.rds.id}"
    availability_zone = "us-west-1b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_internet_gateway" "gw1" {
  vpc_id = "${aws_vpc.rds.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route" "internet_access2" {
  route_table_id         = "${aws_vpc.rds.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw1.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = "${aws_vpc.default.id}"
#  tags {
#    Name = "roche-sg"
#  }

  ingress {
    protocol    = "tcp"
    from_port   = 1
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    protocol        = "tcp"
    from_port       = 1
    to_port         = 65535
    cidr_blocks     = ["0.0.0.0/0"]
#    prefix_list_ids = ["pl-12c4e678"]
  }
}

##################

# Creating an instance
resource "aws_instance" "k8s" {
    ami = "${var.ami_k8s}"
    instance_type = "t2.large"
    subnet_id = "${aws_subnet.subnet1.id}"
    associate_public_ip_address = true
    key_name = "shawnaws"
#    tags {
#        Name = "roche-k8s"
#    }
    security_groups = ["${aws_security_group.allow_all.id}"]
}
