# --- 1. REDE: VPC E SUBREDES ---

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/22"
  tags = {
    Name = "novalocacoes-vpc"
  }
}

# Sub-rede pública: novalocacoes-subnet-public1 (10.0.0.0/26)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "novalocacoes-subnet-public"
  }
}

# Sub-rede privada: novalocacoes-subnet-private1 (10.0.2.0/26)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "novalocacoes-subnet-private"
  }
}

# --- 2. REDE: INTERNET E NAT GATEWAYS ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "novalocacoes-igw"
  }
}

# IP Elástico para o NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "EIP-nat-gateway"
  }
}

# NAT Gteway (Para o envio de emails do backend funcionar)
# Fica na subrede pública e serve a subrede privada
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "novalocacoes-nat-gateway"
  }
  depends_on = [aws_internet_gateway.igw]
}

# --- 3. REDE: TABELAS DE ROTA ---

# Tabela de Rota PÚBLICA (Web Server NGINX)
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "novalocacoes-rtb-public"
  }
}
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rtb.id
}

# Tabela de Rota PRIVADA (backend, frontend, banco, rabbitmq)
resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "novalocacoes-rtb-private"
  }
}
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rtb.id
}

# S3 Gateway Endpoint (permite acesso da subrede privada ao S3)
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  # Associa o endpoint a tabela de rota PRIVADA
  route_table_ids = [aws_route_table.private_rtb.id]
  tags = {
    Name = "endpoint-s3"
  }
}
# --- 4. SEGURANÇA: Security Groups ---

# SG Para o Nginx (Load Balancer e Bastion Host)
resource "aws_security_group" "nginx_sg" {
  name        = "security-group-nginx-public"
  vpc_id      = aws_vpc.main.id
  description = "Permite HTTP, SSH e Painel RabbitMQ"

  # SSH (Porta 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
    description = "SSH access"
  }

  # HTTP (Porta 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # Painel do RabbitMQ (Porta 15672)
  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
    description = "RabbitMQ Painel access"
  }

  # Saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "security-group-nginx-public"
  }
}

# SG Para o frontend
resource "aws_security_group" "frontend_sg" {
  name        = "security-group-frontend-private"
  vpc_id      = aws_vpc.main.id
  description = "Acesso do Nginx (Porta 80) e SSH (via Nginx)"

  # SSH (Porta 22) apenas do Nginx/Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  # Front (Porta 80) apenas do Nginx
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  # Saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG para o backend
resource "aws_security_group" "backend_sg" {
  name        = "security-group-backend-private"
  vpc_id      = aws_vpc.main.id
  description = "Acesso do Nginx (Porta 8082) e SSH (via Nginx)"

  # SSH (Porta 22) apenas do Nginx/Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  # API Backend (Porta 8082) apenas do Nginx
  ingress {
    from_port       = 8082
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  # Saída liberada (Banco, RabbitMq, S3, Google Mail)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG para o Banco (MySQL)
resource "aws_security_group" "database_sg" {
  name        = "security-group-database-private"
  vpc_id      = aws_vpc.main.id
  description = "Acesso do Backend (Porta 3306) e SSH (via Nginx)"

  # SSH (Porta 22) apenas do Nginx/Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  # MySQL (Porta 3306) apenas do Backend
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  # Saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG para o RabbitMQ
resource "aws_security_group" "rabbitmq_sg" {
  name        = "security-group-rabbitmq-private"
  vpc_id      = aws_vpc.main.id
  description = "Acesso do Backend (5672) e Nginx (15672 e 22)"

  # SSH (Porta 22) apenas do Nginx/Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  # AMQP (Porta 5672) apenas do Backend
  ingress {
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  # Painel (Porta 15672) apenas do Nginx (WebServer)
  ingress {
    from_port       = 15672
    to_port         = 15672
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  # Saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}