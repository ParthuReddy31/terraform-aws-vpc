# user can create perring if needed
resource "aws_vpc_peering_connection" "default" {
    count = var.is_peering_required ? 1:0 
    # requester
    vpc_id        = aws_vpc.main.id 
    # accepter
    peer_vpc_id   = local.default_vpc_id
    auto_accept   = true

    tags = merge(
        var.common_tags,
        var.peering_tags,
        {
            Name = "${local.resource_name}-default"
        }
    )
}

# creating peering connection route for public subnets
resource "aws_route" "public_subnet_peering" {
    count = var.is_peering_required ? 1:0 
    route_table_id            = aws_route_table.public.id
    destination_cidr_block    = local.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}
# creating peering connection route for private subnets
resource "aws_route" "private_subnet_peering" {
    count = var.is_peering_required ? 1:0 
    route_table_id            = aws_route_table.private.id
    destination_cidr_block    = local.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}
# creating peering connection route for database subnets
resource "aws_route" "database_subnet_peering" {
    count = var.is_peering_required ? 1:0 
    route_table_id            = aws_route_table.database.id
    destination_cidr_block    = local.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

# creating peering connection route for default vpc 
resource "aws_route" "default_peering" {
    count = var.is_peering_required ? 1:0 
    route_table_id            = data.aws_route_table.main.route_table_id
    destination_cidr_block    = var.vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}