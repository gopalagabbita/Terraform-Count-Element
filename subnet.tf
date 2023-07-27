resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.dev.id
  cidr_block        = element(var.public_cidr_block, count.index + 1)
  availability_zone = element(var.azs, count.index + 1)
  tags = {
    "Name" = "${var.vpc_name}-public${count.index + 1}"

  }
}

resource "aws_route_table" "dev-rt" {
  vpc_id = aws_vpc.dev.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    "Name" = "${var.vpc_name}-rt"
  }
}

resource "aws_route_table_association" "association" {
  count          = 2
  subnet_id      = element(aws_subnet.public.*.id, count.index + 1)
  route_table_id = aws_route_table.dev-rt.id

}

resource "aws_security_group" "dev-sg" {
  vpc_id      = aws_vpc.dev.id
  name        = "Allow all Rules"
  description = "Creating Security Groups for Dev"
  tags = {
    "Name" = "${var.vpc_name}-sg"
  }
  ingress {
    description = "allow all inbound rules"
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all outbound rules"
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dev-server" {
  count                       = 1
  ami                         = "ami-0f9ce67dcf718d332"
  instance_type               = "t2.micro"
  key_name                    = "ec2-tutorials"
  vpc_security_group_ids      = [aws_security_group.dev-sg.id]
  subnet_id                   = element(aws_subnet.public.*.id, count.index + 1)
  associate_public_ip_address = true
  user_data                   = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install nginx1.12 -y
    service nginx start
    echo "<div><h1>PUBLIC-SERVER</h1></div>" >> /usr/share/nginx/html/index.html
    EOF
  tags = {
    "Name" = "${var.vpc_name}-server"
  }
}
