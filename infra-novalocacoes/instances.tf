# --- Instâncias EC2 ---

# IP Elástico para o Nginx/WebServer
resource "aws_eip" "nginx_eip" {
  domain = "vpc"
  tags = {
    Name = "EIP-web-server-nginx"
  }
}

# Instância 1: Web Server Nginx - (Load Balancer) - Pública
resource "aws_instance" "nginx_server" {
  ami                         = var.ami_webserver
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.nginx_sg.id]
  private_ip                  = "10.0.0.53"
  associate_public_ip_address = false

  tags = {
    Name = "web-server-novalocacoes"
  }
}

# Associação do EIP com a instância Nginx
resource "aws_eip_association" "nginx_eip_assoc" {
  instance_id   = aws_instance.nginx_server.id
  allocation_id = aws_eip.nginx_eip.id
}

# Instância 2: Frontend 1 - Privada

resource "aws_instance" "frontend_server_1" {
  ami                    = var.ami_frontend
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  private_ip             = "10.0.2.53"

  tags = {
    Name = "frontend-novalocacoes"
  }
}

# Instância 3: Frontend 2 - Privada

resource "aws_instance" "frontend_server_2" {
  ami                    = var.ami_frontend
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  private_ip             = "10.0.2.54"

  tags = {
    Name = "frontend-novalocacoes-2"
  }
}

# Instância 4: Backend 1 - Privada

resource "aws_instance" "backend_server_1" {
  ami                    = var.ami_backend
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  iam_instance_profile   = "EMR_EC2_DefaultRole"
  private_ip             = "10.0.2.40"

  tags = {
    Name = "backend-novalocacoes"
  }
}

# Instância 5: Backend 2 - Privada

resource "aws_instance" "backend_server_2" {
  ami                    = var.ami_backend
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  iam_instance_profile   = "EMR_EC2_DefaultRole"
  private_ip             = "10.0.2.33"

  tags = {
    Name = "backend-novalocacoes-2"
  }
}

# Instância 6: Banco de Dados - Privada

resource "aws_instance" "database_server" {
  ami                    = var.ami_database
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  private_ip             = "10.0.2.27"

  tags = {
    Name = "banco-novalocacoes"
  }
}

# Instância 7: RabbitMQ - Privada

resource "aws_instance" "rabbitmq_server" {
  ami                    = var.ami_rabbitmq
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.rabbitmq_sg.id]
  private_ip             = "10.0.2.21"

  tags = {
    Name = "consumidor-rabbitmq"
  }
}