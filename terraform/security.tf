resource "aws_security_group" "alb" {
  name        = "verified-access-alb-sg"
  description = "HTTPS ingress from the Verified Access endpoint to the internal ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTPS from Verified Access endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.verified_access_endpoint.id]
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

resource "aws_security_group" "verified_access_endpoint" {
  name        = "verified-access-endpoint-sg"
  description = "Network interfaces for the Verified Access endpoint"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow HTTPS to the internal ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "verified-access-endpoint-sg" }
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
