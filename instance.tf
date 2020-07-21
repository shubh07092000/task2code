provider "aws"{
  profile = "ash"
  region  = "ap-south-1"
}

resource "aws_instance" "task2"{
  ami = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "keycloudclass"
  security_groups = [ "http" ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Shubh/Downloads/keycloudclass.pem")
    host     = aws_instance.task2.public_ip
  }


  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
  }
  tags = {
    Name = "task"
  }
}


resource "aws_security_group" "http" {
  name        = "http"
  description = "Allow tcp inbound traffic"

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  ingress {
    description = "TLS from VPC"
    from_port   = 2049
    to_port     = 2049
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



resource "aws_efs_file_system" "efs1" {
 depends_on = [
  aws_security_group.http,
] 
 creation_token = "my-product"

  tags = {
    Name = "myEFS"
  }
}



resource "aws_efs_mount_target" "alpha" {
  depends_on = [
  aws_efs_file_system.efs1,
]
  file_system_id = "${aws_efs_file_system.efs1.id}"
  subnet_id      = "${aws_instance.task2.subnet_id}"
  security_groups = [ aws_security_group.http.id ]
}



resource "null_resource" "nullremote2"{
depends_on = [
  aws_efs_mount_target.alpha,
]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Shubh/Downloads/keycloudclass.pem")
    host     = aws_instance.task2.public_ip
  }


  provisioner "remote-exec" {
    inline = [
      "sudo echo ${aws_efs_file_system.efs1.dns_name}:/var/www/html efs defaults,_netdev 0 0>> sudo /etc/fstab",
      "sudo mount ${aws_efs_file_system.efs1.dns_name}:/ /var/www/html/",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/shubh07092000/cloudtask1.git /var/www/html"
      
    ]
  }
}

resource "aws_s3_bucket" "mys3" {
  bucket = "shubh0709"
  acl    = "public-read"
  
  tags = {
    Name = "shubhtask1"
  }
  versioning{
    enabled = true

  }

 }
locals {
  s3_origin_id = "myS3Origin"
}




resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "shubh0709.s3.amazonaws.com"
    origin_id   = "S3-shubh0709"

    
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "shubh0709.s3.amazonaws.com"
    prefix          = "myprefix"
  }


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-shubh0709"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-shubh0709"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-shubh0709"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_s3_bucket_object" "s3obj" {
  depends_on = [
  aws_s3_bucket.mys3,
]
  bucket = "shubh0709"
  key    = "friends.jpg"
  source = "C:/Users/Shubh/Desktop/friends.jpg"
  acl = "public-read"
  content_type = "image or jpg"
  }

resource "null_resource" "null"{
  provisioner "local-exec"{
    command = "echo ${aws_instance.task2.public_ip} > publicip.txt"
  }
}