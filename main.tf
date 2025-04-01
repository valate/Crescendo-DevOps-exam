

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "crescendo-exam-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "crescendo-igw" }
}

# Public Subnets
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
  tags = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
  tags = { Name = "public-subnet-2" }
}

# Private Subnets
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-1a"
  tags = { Name = "private-subnet-1" }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-1b"
  tags = { Name = "private-subnet-2" }
}

# NAT Gateway (in public subnet 1)
resource "aws_eip" "nat" {
domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id
  tags = { Name = "crescendo-nat" }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "private-rt" }
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance with Nginx and Tomcat on Ubuntu 24.04
resource "aws_instance" "web1" {
  ami           = "ami-01938df366ac2d954"  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private1.id
  security_groups = [aws_security_group.ec2.id]
 user_data = <<-EOF
                #!/bin/bash
                # Update and install Nginx
                apt-get update -y
                apt-get install -y nginx
                systemctl start nginx
                systemctl enable nginx

                # Install Java for Tomcat
                apt-get install -y default-jdk

                # Download and Install Tomcat
                wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.58/bin/apache-tomcat-9.0.58.tar.gz -P /tmp
                tar -xvf /tmp/apache-tomcat-9.0.58.tar.gz -C /opt
                mv /opt/apache-tomcat-9.0.58 /opt/tomcat

                # Start Tomcat
                /opt/tomcat/bin/startup.sh


                # Enable Tomcat on reboot
                cat <<'EOF2' > /etc/systemd/system/tomcat.service
                [Unit]
                Description=Apache Tomcat Web Application Container
                After=network.target

                [Service]
                Type=forking

                ExecStart=/opt/tomcat/bin/startup.sh
                ExecStop=/opt/tomcat/bin/shutdown.sh

                User=root
                Group=root

                [Install]
                WantedBy=multi-user.target
                EOF2

                systemctl daemon-reload
                systemctl enable tomcat
                systemctl start tomcat
              EOF

  tags = { Name = "web1" }
}



resource "aws_instance" "web2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private2.id
  security_groups = [aws_security_group.ec2.id]
  user_data = <<-EOF
                #!/bin/bash
                # Update and install Nginx
                apt-get update -y
                apt-get install -y nginx
                systemctl start nginx
                systemctl enable nginx

                # Install Java for Tomcat
                apt-get install -y default-jdk

                # Download and Install Tomcat
                wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.58/bin/apache-tomcat-9.0.58.tar.gz -P /tmp
                tar -xvf /tmp/apache-tomcat-9.0.58.tar.gz -C /opt
                mv /opt/apache-tomcat-9.0.58 /opt/tomcat

                # Start Tomcat
                /opt/tomcat/bin/startup.sh


                # Enable Tomcat on reboot
                cat <<'EOF2' > /etc/systemd/system/tomcat.service
                [Unit]
                Description=Apache Tomcat Web Application Container
                After=network.target

                [Service]
                Type=forking

                ExecStart=/opt/tomcat/bin/startup.sh
                ExecStop=/opt/tomcat/bin/shutdown.sh

                User=root
                Group=root

                [Install]
                WantedBy=multi-user.target
                EOF2

                systemctl daemon-reload
                systemctl enable tomcat
                systemctl start tomcat
              EOF
  tags = { Name = "web2" }
}

# Application Load Balancer
resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "web1" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
  tags = { Name = "crescendo-alb" }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_lb.web.dns_name
    origin_id   = "alb-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  enabled             = true
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction { restriction_type = "none" }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  tags = { Name = "crescendo-cdn" }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id  

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "private" {
  name       = "private-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]  
  tags = {
    Name = "private-subnet-group"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "13.4"
  instance_class         = "db.t3.micro"  
  identifier             = "crescendo-db"
  username               = "postgres"
  password               = "rdspasstest"  
  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false  
  skip_final_snapshot    = true   
  tags = {
    Name = "crescendo-postgres"
  }
}
