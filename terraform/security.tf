resource "aws_security_group" "alb" {
  name        = "verified-access-alb-sg"
  description = "Public HTTPS entry point for the ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from the internet to ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow ALB outbound to application"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "verified-access-alb-sg" }
}

resource "aws_security_group" "app" {
  name        = "verified-access-app-sg"
  description = "Only the ALB can reach the Flask application"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Flask from ALB only"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Application outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "verified-access-app-sg" }
}
