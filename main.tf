provider "aws" {
  region = "eu-central-1"
}

####################### VPC ###############################################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
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
  subnet_id      = aws_subnet.public2.id
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
  route_table_ids = [aws_route_table.private_route_table.id]  # Verwenden Sie die Route-Tabelle des öffentlichen Subnets
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
  route_table_ids = [aws_route_table.private_route_table2.id]  # Verwenden Sie die Route-Tabelle des öffentlichen Subnets
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
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
}

resource "aws_lb_target_group" "TG1" {
  name     = "TG1"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group" "TG2" {
  name     = "TG2"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}


# # ALB auf Ec2 1
# resource "aws_lb_target_group_attachment" "TG1" {
#   target_group_arn = aws_lb_target_group.TG1.arn
#   target_id        = aws_autoscaling_group.web_asg.id
#   port             = 80
# }

# # ALB auf Ec2 2
# resource "aws_lb_target_group_attachment" "TG2" {
#   target_group_arn = aws_lb_target_group.TG2.arn
#   target_id        = aws_autoscaling_group.web_asg.id
#   port             = 80
# }


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

####################### DynamoDB ###############################################

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

 hash_key        ="LockID"
}

####################### S3 ###############################################

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "jfschraube24.de"
  acl    = "private"

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
  bucket = "jsdatenbucket"  # Ersetzen Sie durch Ihren gewünschten Bucket-Namen
  acl    = "private"

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
        Action   = ["s3:ListBucket"],
        Effect   = "Allow",
        Resource = ["arn:aws:s3:::jfschraube24.de"]
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject"],
        Effect   = "Allow",
        Resource = ["arn:aws:s3:::jfschraube24.de/*"]
      }
    ]
  })
}

###### IAM-Policy, die DynamoDB-Zugriffsberechtigungen gewährt:

resource "aws_iam_policy" "dynamodb_access" {
  name        = "dynamodb_access"
  description = "Allow EC2 instance to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:ListTables"
        ],
        Effect   = "Allow",
        Resource = ["arn:aws:dynamodb:*:*:table/terraform-locks"]
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
  key_name      = "provisioners_key"

  network_interfaces {
    subnet_id              = aws_subnet.private1.id
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
sudo npm install -g pm2
sudo yum install -y awscli
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app


aws s3 sync s3://jsdatenbucket/ /home/ec2-user/app
tar -xvf node-app.tar

cd node-app/backend
sudo npm install
sudo chmod +x server.js
pm2 start server.js --name backend
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
  key_name      = "provisioners_key"

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
sudo npm install -g pm2
sudo yum install -y awscli
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

aws s3 sync /home/ec2-user/app s3://jsdatenbucket/./
cd node-app/backend

sudo npm install
sudo chmod +x server.js
pm2 start server.js --name backend
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "private_web_2"
    }
  }
}











################################################################################################
################################################################################################
################################################################################################
################################################################################################


# ############################ EC2 1 ################################################


# # Erstellt eine öffentliche EC2-Instanz im öffentlichen Subnetz
# resource "aws_instance" "private_web_1" {
#   ami           = "ami-0766f68f0b06ab145" # Beispiel-AMI-ID. Ersetzen Sie dies durch die gewünschte AMI-ID.
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.private1.id
#   vpc_security_group_ids = [aws_security_group.ec2_sg_privat1.id] # für instance
#   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  
#   key_name = "provisioners_key"   # !!!!!!!!!!!!!!Key public anpassen

#    connection {
#     type     = "ssh"
#     user     = "ec2-user"
#     private_key = file("C:/Users/andye/Documents/AWS/AndysTestServer/provisioners_key.pem") # !!!!!!!!!!!!!!!!!!Key Privat anpassen
#     host     = self.public_ip
#   }
# # ausgefürte Befehle die auf der Maschiene laufen
#   provisioner "remote-exec" {
#     inline = [
#       "sudo yum install -y nodejs",
#       "sudo npm install pm2 -g",

#     ]
#   }
# # Ordner erstellen
#   provisioner "remote-exec" {
#     inline = ["mkdir -p /home/ec2-user/app"]
#   }

# # Local ausgefürt, schreibt ausgewählte datei oder Verzeichnis in die EC2
#   provisioner "file" {
#     source      = "./node-app/" # !!!!!!!!!!!!!!!!!!!!!!!!!!!!Path anpassen
#     destination = "/home/ec2-user/app/" # !!!!!!!!!!!!!!!!!!!!!!!!!!!!Path anpassen
#   }

  

#   # node ausführen nachdem das Verzeichnis kopiert ist backend
#   provisioner "remote-exec" {
#     inline = [
#       "sudo chmod +x /home/ec2-user/app/node-app/backend/server.js",
#       "cd /home/ec2-user/app/backend/",
#       # "sudo npm init -y",
#       "sudo npm install -y",
#       # "nohup node server.js > /dev/null 2>&1 &",
#       "pm2 start server.js --name backend",
#       # "npm start",
#     ]
#   }
# }

# ############################ EC2 2 ################################################


# # Erstellt eine öffentliche EC2-Instanz im öffentlichen Subnetz
# resource "aws_instance" "private_web_2" {
#   ami           = "ami-0766f68f0b06ab145" # Beispiel-AMI-ID. Ersetzen Sie dies durch die gewünschte AMI-ID.
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.private2.id
#   vpc_security_group_ids = [aws_security_group.ec2_sg_privat1.id] # für instance
#   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  
#   key_name = "provisioners_key"   # !!!!!!!!!!!!!!Key public anpassen

#    connection {
#     type     = "ssh"
#     user     = "ec2-user"
#     private_key = file("C:/Users/andye/Documents/AWS/AndysTestServer/provisioners_key.pem") # !!!!!!!!!!!!!!!!!!Key Privat anpassen
#     host     = self.public_ip
#   }
# # ausgefürte Befehle die auf der Maschiene laufen
#   provisioner "remote-exec" {
#     inline = [
#       "sudo yum install -y nodejs",
#       "sudo npm install pm2 -g",
#     ]
#   }
# # Ordner erstellen
#   provisioner "remote-exec" {
#     inline = ["mkdir -p /home/ec2-user/app"]
#   }

# # Local ausgefürt, schreibt ausgewählte datei oder Verzeichnis in die EC2
#   provisioner "file" {
#     source      = "./node-app/" # !!!!!!!!!!!!!!!!!!!!!!!!!!!!Path anpassen
#     destination = "/home/ec2-user/app/" # !!!!!!!!!!!!!!!!!!!!!!!!!!!!Path anpassen
#   }

  

#   # node ausführen nachdem das Verzeichnis kopiert ist backend
#   provisioner "remote-exec" {
#     inline = [
#       "sudo chmod +x /home/ec2-user/app/node-app/backend/server.js",
#       "cd /home/ec2-user/app/backend/",
#       # "sudo npm init -y",
#       "sudo npm install -y",
#       # "nohup node server.js > /dev/null 2>&1 &",
#       "pm2 start server.js --name backend",
#       # "npm start",
#     ]
#   }
# }

