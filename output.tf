# -------------------------------------------------------
# TECHNOGIX
# -------------------------------------------------------
# Copyright (c) [2022] Technogix SARL
# All rights reserved
# -------------------------------------------------------
# Module to deploy an aws vpn endpoint with all the secure
# components required
# -------------------------------------------------------
# Nadège LEMPERIERE, @14 november 2021
# Latest revision: 14 november 2021
# -------------------------------------------------------

output "vpn" {
    value = {
        id = aws_ec2_client_vpn_endpoint.endpoint.id
        arn =  aws_ec2_client_vpn_endpoint.endpoint.arn
        dns = aws_ec2_client_vpn_endpoint.endpoint.dns_name
        status = aws_ec2_client_vpn_endpoint.endpoint.status
    }
}

output "interfaces" {
    value = null_resource.interfaces.*.triggers
}
