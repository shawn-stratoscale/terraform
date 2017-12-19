# Creating a VPC & Networking
resource "aws_vpc" "default" {
    cidr_block = "192.168.0.0/16"
    enable_dns_support = false
}

resource "aws_vpc" "rds" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = false
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
  }
  
  ingress {
    protocol    = "udp"
    from_port   = 1
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol        = "udp"
    from_port       = 1
    to_port         = 65535
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_all_db" {
  name        = "allow_all_db"
  description = "Allow all traffic to db"
  vpc_id      = "${aws_vpc.rds.id}"

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
  }

  ingress {
    protocol    = "udp"
    from_port   = 1
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol        = "udp"
    from_port       = 1
    to_port         = 65535
    cidr_blocks     = ["0.0.0.0/0"]
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
    security_groups = ["${aws_security_group.allow_all.id}"]
}

resource "aws_eip_association" "eip_k8s" {
  instance_id   = "${aws_instance.k8s.id}"
  allocation_id = "${aws_eip.k8s.id}"
}

resource "aws_eip" "k8s" {
  vpc = true
}

resource "aws_eip" "k8s2" {
  vpc = true
}

# Creating an instance
resource "aws_instance" "k8s2" {
    ami = "${var.ami_k8s}"
    instance_type = "t2.large"
    subnet_id = "${aws_subnet.subnet1.id}"
    associate_public_ip_address = true
    key_name = "shawnaws"
    security_groups = ["${aws_security_group.allow_all.id}"]
}

resource "aws_eip_association" "eip_k8s2" {
  instance_id   = "${aws_instance.k8s2.id}"
  allocation_id = "${aws_eip.k8s2.id}"
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.default.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}

resource "aws_db_subnet_group" "dbsubnet" {
  name       = "main"
  subnet_ids = ["${aws_subnet.subnet2.id}"]
}

# Create db instance 1
resource "aws_db_instance" "db-igt" {
  identifier = "db-igt"
  instance_class = "t2.micro"
  allocated_storage = 10
  engine = "mysql"
  name = "db123"
  password = "dbpassword"
  username = "terraform"
  engine_version = "5.7.00"
  skip_final_snapshot = true
  db_subnet_group_name = "${aws_db_subnet_group.dbsubnet.name}"
  publicly_accessible = true
  vpc_security_group_ids   = ["${aws_security_group.allow_all_db.id}"]
}
