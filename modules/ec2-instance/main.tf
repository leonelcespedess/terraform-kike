resource "aws_instance" "my_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  security_groups = [aws_security_group.my_sg.name]

  key_name               = "terraform-key"
  user_data = file("${path.module}/install_nginx.sh")

  tags = {
    Name = "TerraformExample"
  }
}

resource "aws_security_group" "my_sg" {
  name        = "example_security_group"
  description = "Allow inbound traffic on port 22 (SSH) and 443 (HTTPS)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic" # Opcional: una descripción para la regla
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "my_eip" {
  instance = aws_instance.my_instance.id
}

resource "aws_eip_association" "my_eip_association" {
  instance_id   = aws_instance.my_instance.id
  allocation_id = aws_eip.my_eip.id
}

output "elastic_ip" {
  value = aws_eip.my_eip.public_ip
}