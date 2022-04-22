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

# -------------------------------------------------------
# Create the vpn client
# -------------------------------------------------------
resource "aws_ec2_client_vpn_endpoint" "endpoint" {

	description            	= "${var.project}.${var.environment}.${var.module}.vpn.${var.vpn.name}"
  	server_certificate_arn 	= var.vpn.certificate
  	client_cidr_block      	= var.vpn.cidr
	dns_servers				= [cidrhost(var.vpc.cidr, 2)]
	transport_protocol 		= "udp"

  	authentication_options {
    	type              = "federated-authentication"
    	saml_provider_arn = aws_iam_saml_provider.endpoint_application.arn
  	}

  	connection_log_options {
    	enabled               	= true
    	cloudwatch_log_group  	= var.logging.loggroup
    	cloudwatch_log_stream 	= aws_cloudwatch_log_stream.endpoint_stream.name
  	}

  	tags = {
		Name           	= "${var.project}.${var.environment}.${var.module}.vpn.${var.vpn.name}"
		Environment     = var.environment
		Owner   		= var.email
		Project   		= var.project
		Version 		= var.git_version
		Module  		= var.module
	}
}

# -------------------------------------------------------
# Create identity provider for VPN sso application
# -------------------------------------------------------
resource "aws_iam_saml_provider" "endpoint_application" {
  	name                   = "${var.project}.${var.environment}.${var.module}.vpn.${var.vpn.name}.provider"
 	saml_metadata_document = var.vpn.saml

  	tags = {
		Name           	= "${var.project}.${var.environment}.${var.module}.vpn.${var.vpn.name}.saml"
		Environment     = var.environment
		Owner   		= var.email
		Project   		= var.project
		Version 		= var.git_version
		Module  		= var.module
	}
}

# -------------------------------------------------------
# Create logstream to monitor vpn access
# -------------------------------------------------------
resource "aws_cloudwatch_log_stream" "endpoint_stream" {
	name           = "${var.project}.${var.environment}.${var.module}.vpn.${var.vpn.name}"
	log_group_name = var.logging.loggroup
}

# -------------------------------------------------------
# Enable the group laptops owners to access services through vpn subnets
# -------------------------------------------------------
resource "aws_ec2_client_vpn_authorization_rule" "endpoint_authorizations" {

	count = length(var.vpn.authorizations)

	client_vpn_endpoint_id 	= aws_ec2_client_vpn_endpoint.endpoint.id
	target_network_cidr    	= var.vpn.authorizations[count.index]
	access_group_id   		= var.vpn.group
}

# -------------------------------------------------------
# Create the client security group
# -------------------------------------------------------
resource "aws_security_group" "endpoint_sgs" {

  	name        = "${var.project}.${var.environment}.${var.module}.vpn.${var.vpn.name}.nsg"
  	description = "Allow vpn endpoint traffic in a given subnet"
  	vpc_id      = var.vpc.id

	tags = {
		Name           		= "${var.project}.${var.environment}.${var.module}.vpn.${var.vpn.name}.nsg"
		Environment     	= var.environment
		Owner   			= var.email
		Project   			= var.project
		Version 			= var.git_version
		Module  			= var.module
	}
}

# -------------------------------------------------------
# Associate subnet to vpn through security group rules
# -------------------------------------------------------
resource "aws_ec2_client_vpn_network_association" "endpoint_subnets" {

	count = length(var.subnets)

	client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.endpoint.id
  	subnet_id              = var.subnets[count.index].id
	security_groups        = [aws_security_group.endpoint_sgs.id]
}

# -------------------------------------------------------
# Create routes from vpn to resources in vpc route table
# -------------------------------------------------------
locals {
	routes = flatten([	for i, sub in var.subnets : [ for j, route in sub.routes : { route = route, subnet = sub.id}]])
}
resource "aws_ec2_client_vpn_route" "endpoint_routes" {

	count = length(local.routes)

	depends_on				= [aws_ec2_client_vpn_network_association.endpoint_subnets]
  	client_vpn_endpoint_id 	= aws_ec2_client_vpn_endpoint.endpoint.id
  	destination_cidr_block 	= local.routes[count.index].route
  	target_vpc_subnet_id   	= local.routes[count.index].subnet
}

# -------------------------------------------------------
# Add rules in vpn nsg to enable vpn access to resources
# -------------------------------------------------------
resource "aws_security_group_rule" "endpoint_egress" {

	count = length(var.rules.egress)

	depends_on					= [aws_security_group.endpoint_sgs]
	description					= var.rules.egress[count.index].description
  	security_group_id 			= aws_security_group.endpoint_sgs.id
  	type         				= "egress"
  	protocol       				= var.rules.egress[count.index].protocol
  	cidr_blocks    				= ["${var.rules.egress[count.index].cidr}"]
    ipv6_cidr_blocks 			= []
	prefix_list_ids 			= []
  	from_port      				= var.rules.egress[count.index].from
  	to_port        				= var.rules.egress[count.index].to
}
resource "aws_security_group_rule" "endpoint_ingress" {

	count = length(var.rules.ingress)

	depends_on					= [aws_security_group.endpoint_sgs]
	description					= var.rules.ingress[count.index].description
  	security_group_id 			= aws_security_group.endpoint_sgs.id
  	type         				= "ingress"
  	protocol       				= var.rules.ingress[count.index].protocol
  	cidr_blocks    				= ["${var.rules.ingress[count.index].cidr}"]
    ipv6_cidr_blocks 			= []
	prefix_list_ids 			= []
  	from_port      				= var.rules.ingress[count.index].from
  	to_port        				= var.rules.ingress[count.index].to
}

# -------------------------------------------------------
# Formatting data for output
# -------------------------------------------------------
resource "null_resource" "interfaces" {

    count = length(var.subnets)

    triggers = {
        group = aws_security_group.endpoint_sgs.id
        subnet = var.subnets[count.index].id
        association = aws_ec2_client_vpn_network_association.endpoint_subnets[count.index].id
    }
}
