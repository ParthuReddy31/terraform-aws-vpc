# user can create perring if needed
resource "aws_vpc_peering_connection" "foo" {
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