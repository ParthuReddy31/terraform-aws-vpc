# creating VPC with CIDR 
resource "aws_vpc" "main" {
    cidr_block       = var.vpc_cidr
    enable_dns_hostnames = var.enable_dns_hostnames
    instance_tenancy = "default"

    tags = merge(
        var.common_tags,
        var.vpc_tags,
        {
            Name = local.resource_name
        }
    )
}

# creating internet gateway and attaching to vpc
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.common_tags,
        var.igw_tags,
        {
            Name = local.resource_name
        }
    )
}

# creating public subnets in two availability zones
# expense-dev-public-us-east-1a
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidr)
    vpc_id     = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]
    map_public_ip_on_launch = true

    tags = merge(
        var.common_tags,
        var.public_subnet_tags,
        {
            Name = "${local.resource_name}-public-${local.az_names[count.index]}"
        }
        
    )
}

# creating private subnets in two availability zones
# expense-dev-private-us-east-1a
resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidr)
    vpc_id     = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]

    tags = merge(
        var.common_tags,
        var.private_subnet_tags,
        {
            Name = "${local.resource_name}-private-${local.az_names[count.index]}"
        }
        
    )
}

# creating database subnets in two availability zones
# expense-dev-database-us-east-1a
resource "aws_subnet" "database" {
    count = length(var.database_subnet_cidr)
    vpc_id     = aws_vpc.main.id
    cidr_block = var.database_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]

    tags = merge(
        var.common_tags,
        var.database_subnet_tags,
        {
            Name = "${local.resource_name}-database-${local.az_names[count.index]}"
        }
    )
    
}

# creating the elastic ip to attach nat-gateway
resource "aws_eip" "nat" {
    domain   = "vpc"
}

# creating NAT-gateway 
resource "aws_nat_gateway" "example" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public[0].id

    tags = merge (var.common_tags,
        var.nat_gateway_tags,
    {
        Name = local.resource_name
    }
    )
    # To ensure proper ordering, it is recommended to add an explicit dependency
    # on the Internet Gateway for the VPC.
    depends_on = [aws_internet_gateway.main]
}

# creating public route table 
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.common_tags,
        var.public_route_table_tags,
    {
    Name = "${local.resource_name}-public"
    }
    )
}

# creating private route table 
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.common_tags,
        var.private_route_table_tags,
    {
    Name = "${local.resource_name}-private"
    }
    )
}

# creating database route table
resource "aws_route_table" "database" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.common_tags,
        var.database_route_table_tags,
    {
    Name = "${local.resource_name}-database"
    }
    )
}
# creating public route through IGW
resource "aws_route" "public" {
    route_table_id            = aws_route_table.public.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
}
# creating private route through NAT Gateway
resource "aws_route" "private" {
    route_table_id            = aws_route_table.private.id
    destination_cidr_block    = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
}
# creating database route through NAT Gateway
resource "aws_route" "database" {
    route_table_id            = aws_route_table.database.id
    destination_cidr_block    = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
}
# associating public subnets with public route table  
resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidr)
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}
# associating private subnets with private route table
resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidr)
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}
# associating database subnets with database route table
resource "aws_route_table_association" "database" {
    count = length(var.database_subnet_cidr)
    subnet_id      = aws_subnet.database[count.index].id
    route_table_id = aws_route_table.database.id
}

