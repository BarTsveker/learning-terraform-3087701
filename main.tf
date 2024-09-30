# main.tf

# VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block = "10.64.0.0/16"

  tags = {
    Name = "bar-vpc"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.64.1.0/24"
  availability_zone = "${var.aws_region}a" 

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.64.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "public-subnet-b"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Groups
resource "aws_security_group" "allow_http" {
  name = "allow_http"
  vpc_id = aws_vpc.main.id

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

  tags = {
    Name = "allow_http"
  }
}

# Launch Configuration
resource "aws_launch_configuration" "web_server" {
  name_prefix                 = "web-server-lc-"
  image_id                    = var.ami_id
  instance_type               = var.instance_type
  security_groups              = [aws_security_group.allow_http.id]

  user_data = <<EOF
#!/bin/bash
echo "Hello, World! This is from Terraform!" > index.html
nohup python -m SimpleHTTPServer 80 &
EOF
}

# Autoscaling Group
resource "aws_autoscaling_group" "web_server_asg" {
  name                      = "web-server-asg"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 2
  health_check_grace_period = 60
  health_check_type         = "ELB"
  launch_configuration      = aws_launch_configuration.web_server.name
  vpc_zone_identifier       = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  tag {
    key                 = "Name"
    value               = "web-server-asg"
    propagate_at_launch = true
  }
}

# Load Balancer
resource "aws_lb" "web_server_lb" {
  name               = "web-server-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  tags = {
    Name = "web-server-lb"
  }
}

resource "aws_lb_target_group" "web_server_tg" {
  name     = "web-server-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
}

resource "aws_lb_listener" "web_server_listener" {
  load_balancer_arn = aws_lb.web_server_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_tg.arn
  }
}

# Attach ASG to Target Group
resource "aws_autoscaling_attachment" "web_server_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
  target_group_arn       = aws_lb_target_group.web_server_tg.arn
}