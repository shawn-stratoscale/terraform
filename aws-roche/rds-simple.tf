# Create a dbsubnet group
resource "aws_db_subnet_group" "dbsubnet" {
  name       = "main"
  subnet_ids = ["${aws_subnet.subnet2.id}", "${aws_subnet.subnet3.id}"]
}

# Create db instance 1
resource "aws_db_instance" "db-roche" {
  identifier = "db-roche"
  instance_class = "db.t2.micro"
  allocated_storage = 10
  engine = "mysql"
  name = "db123"
  password = "dbpassword"
  username = "terraform"
  engine_version = "5.7.16"
  skip_final_snapshot = true
  db_subnet_group_name = "${aws_db_subnet_group.dbsubnet.name}"
  publicly_accessible = true
}
