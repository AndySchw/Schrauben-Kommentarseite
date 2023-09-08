provider "aws" {
  region = "eu-central-1"
}

####################### VPC ###############################################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

####################### Variablen aus .env Datei einlesen ###############################################

variable "oeffentlicher_key" {
  description = "Der Name des SSH-Schlüssels für die EC2-Instanz öffenltich aus AWS"
  type        = string
}

variable "privater_key" {
  description = "Der Name des SSH-Schlüssels für die EC2-Instanz privat vom Lokalen PC"
  type        = string
}

variable "s3_bucket_kundendaten" {
  description = "Der Name des S3 Bucket auf dem die Kundenbiler gespeichert werden"
  type        = string
}

variable "s3_bucket_zwischenspeicher" {
  description = "Der Name des S3 Bucket zum erstellen der EC2 Maschienen"
  type        = string
}

variable "dynamodb" {
  description = "Der Name der DynamoDB"
  type        = string
}


####################### IGW ###############################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "sub1a-public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "sub1b-public2"
  }
}

resource "aws_route_table_association" "public_route_table_public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_route_table.id
}



resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "sub1a-private"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "sub1b-private"
  }
}

####################### Endpunkte ###############################################


resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
}

#routing endpunkte privat sub 1
resource "aws_route_table_association" "private_route_table_association1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.eu-central-1.dynamodb"
  route_table_ids = [aws_route_table.private_route_table.id]  # Verwenden Sie die Route-Tabelle des privaten Subnets
}

resource "aws_vpc_endpoint" "s3_endpoint1" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.eu-central-1.s3"
  route_table_ids = [aws_route_table.private_route_table.id]  # Verwenden Sie die Route-Tabelle des privaten Subnets
}

#routing endpunkte privat sub 2
resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private_route_table_association2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_route_table2.id
}

resource "aws_vpc_endpoint" "dynamodb_endpoint2" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.eu-central-1.dynamodb"
  route_table_ids = [aws_route_table.private_route_table2.id]  # Verwenden Sie die Route-Tabelle des privaten Subnets
}

resource "aws_vpc_endpoint" "s3_endpoint2" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.eu-central-1.s3"
  route_table_ids = [aws_route_table.private_route_table2.id]  # Verwenden Sie die Route-Tabelle des privaten Subnets
}


####################### SG ###############################################

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"
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

# SG EC2 Privat
resource "aws_security_group" "ec2_sg_private1"{
  name        = "ec2_sg_privat1"
  vpc_id      = aws_vpc.main.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"] # Nur für den öffentliches subnetz
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"] # Nur für den öffentliches subnetz
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Sie könnten dies auf die IP des ALB beschränken, um die Sicherheit zu erhöhen
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"] # Nur für den öffentliches subnetz
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.2.0/24"] # Nur für den öffentliches subnetz
  }

  # Ausgehender Datenverkehr ist offen.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

####################### ALB ###############################################


resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
}

resource "aws_lb_target_group" "TG1" {
  name     = "TG1"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  

  health_check {
      path                = "/"  # Der Pfad zur Gesundheitsprüfung Ihrer Anwendung
      protocol            = "HTTP"
      port                = 3000  # Der Port Ihrer Anwendung auf den EC2-Instanzen
      unhealthy_threshold = 2
      healthy_threshold   = 2
      timeout             = 3
    }
}

resource "aws_lb_target_group" "TG2" {
  name     = "TG2"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
      path                = "/"  # Der Pfad zur Gesundheitsprüfung Ihrer Anwendung
      protocol            = "HTTP"
      port                = 3000  # Der Port Ihrer Anwendung auf den EC2-Instanzen
      unhealthy_threshold = 2
      healthy_threshold   = 2
      timeout             = 3
    }
}


resource "aws_autoscaling_attachment" "asg_attachment_TG1" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  lb_target_group_arn   = aws_lb_target_group.TG1.arn
}

resource "aws_autoscaling_attachment" "asg_attachment_TG2" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  lb_target_group_arn   = aws_lb_target_group.TG2.arn
}



resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.TG1.arn
        weight = 50
      }

      target_group {
        arn    = aws_lb_target_group.TG2.arn
        weight = 50
      }
      
      stickiness {
        enabled  = true
        duration = 300
      }
    }
  }
}


output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

####################### DynamoDB ###############################################

resource "aws_dynamodb_table" "terraform_locks" {
  name           = var.dynamodb
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }

  hash_key        = "id"
}

####################### S3 ###############################################

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = var.s3_bucket_kundendaten
  acl    = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }
}

# neuer bucket für js daten

resource "aws_s3_bucket" "jsdatenbucket" {
  bucket = var.s3_bucket_zwischenspeicher  # Ersetzen Sie durch Ihren gewünschten Bucket-Namen
  acl    = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }
}


resource "aws_s3_bucket_object" "file_upload2" {
  bucket = aws_s3_bucket.jsdatenbucket.bucket
  key    = "./node-app.tar"  # Ersetzen Sie durch Ihren gewünschten Dateipfad
  source = "./node-app/node-app.tar"  # Ersetzen Sie durch den Pfad zur Datei auf Ihrem lokalen System
  acl    = "private"
}



####################### IAM ###############################################

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access" {
  name        = "s3_access"
  description = "Allow EC2 instance to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "s3:*",
        Effect   = "Allow",
        Resource = "*",
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb_access" {
  name        = "dynamodb_access"
  description = "Allow EC2 instance to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "dynamodb:*",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}


####################### Auto Scaling Group ###############################################

resource "aws_autoscaling_group" "web_asg" {
  name                 = "web-asg"
  min_size             = 2
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.private1.id, aws_subnet.private2.id]

  launch_template {
    id = aws_launch_template.private_web_1.id
    version = "$Latest"
  }

  target_group_arns    = [aws_lb_target_group.TG1.arn, aws_lb_target_group.TG2.arn]

  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }
}


locals {
  lb_parts = split("/", aws_lb.web.arn)
  lb_id    = local.lb_parts[length(local.lb_parts) - 1]
  lb_name  = aws_lb.web.name
}

# Auto Scaling Policy for Scale Up
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# Auto Scaling Policy for Scale Down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# CloudWatch Metric Alarm to scale up
resource "aws_cloudwatch_metric_alarm" "scale_up" {
    alarm_name          = "scale-up-on-high-requests"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = "1"
    metric_name         = "RequestCount"
    namespace           = "AWS/ApplicationELB"
    period              = "60"
    statistic           = "Sum"
    threshold           = "1" # Modify this value based on when you want to scale up
    alarm_description   = "This metric triggers when there are too many requests on the ALB"
    alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
    dimensions          ={
        LoadBalancer      ="app/${local.lb_name}/${local.lb_id}"
        AvailabilityZone ="eu-central-1a"
    }
}


####################### Launch Tamplate ###############################################


resource "aws_launch_template" "private_web_1" {
  name          = "private_web_1"
  image_id      = "ami-0766f68f0b06ab145" 
  instance_type = "t2.micro"
  key_name      = var.oeffentlicher_key

  network_interfaces {
    subnet_id              = aws_subnet.private1.id
    security_groups        = [aws_security_group.ec2_sg_private1.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
sudo yum install -y nodejs 
mkdir -p /home/ec2-user/app 
cd /home/ec2-user/app 


sudo aws s3 sync s3://${var.s3_bucket_zwischenspeicher}/ /home/ec2-user/app 
sudo chmod 777 node-app.tar
sudo tar -xvf node-app.tar 

cd node-app/backend 
sudo chmod +x server.js 
sudo node server.js > server.log 2>&1
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "private_web_1"
    }
  }
}


resource "aws_launch_template" "private_web_2" {
  name          = "private_web_2"
  image_id      = "ami-0766f68f0b06ab145" 
  instance_type = "t2.micro"
  key_name      = var.oeffentlicher_key

  network_interfaces {
    subnet_id              = aws_subnet.private2.id
    security_groups        = [aws_security_group.ec2_sg_private1.id]
  }

  # network_interfaces {
  #   network_interface_id = aws_network_interface.example.id
  #   device_index         = 0
  # }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
sudo yum install -y nodejs 
mkdir -p /home/ec2-user/app 
cd /home/ec2-user/app 


sudo aws s3 sync s3://${var.s3_bucket_zwischenspeicher}/ /home/ec2-user/app 
sudo chmod 777 node-app.tar
sudo tar -xvf node-app.tar 

cd node-app/backend 
sudo chmod +x server.js 
sudo node server.js > server.log 2>&1
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "private_web_2"
    }
  }
}
