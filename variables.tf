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
# Contact e-mail for this deployment
# -------------------------------------------------------
variable "email" {
	type 	= string
}

# -------------------------------------------------------
# Environment for this deployment (prod, preprod, ...)
# -------------------------------------------------------
variable "environment" {
	type 	= string
}

# -------------------------------------------------------
# Topic context for this deployment
# -------------------------------------------------------
variable "project" {
	type    = string
}
variable "module" {
	type 	= string
}

# -------------------------------------------------------
# Solution version
# -------------------------------------------------------
variable "git_version" {
	type    = string
	default = "unmanaged"
}

# -------------------------------------------------------
# VPC in which the vpn shall be created
# -------------------------------------------------------
variable "vpc" {
	type = object({
		id 		= string,
		cidr	= string,
    })
}

# --------------------------------------------------------
# VPN description
# --------------------------------------------------------
variable "vpn" {
	type = object({
        name 			= string,
		certificate 	= string,
		cidr			= string,
		saml			= string,
		group			= string,
		authorizations	= list(string)
    })
}

#  -------------------------------------------------------
# Subnets to associate to VPN with security groups rules
# --------------------------------------------------------
variable "subnets" {
	type = list(object({
		id 		= string,
		routes 	= list(string)
	}))
}

#  -------------------------------------------------------
# VPN logging configuration
# --------------------------------------------------------
variable "logging" {
	type = object({
		loggroup = string
	})
}

#  -------------------------------------------------------
# VPN security group rules
# --------------------------------------------------------
variable "rules" {
	type = object({
        egress 	= list(object({
			description = string,
			cidr 		= string,
			from 		= number,
			to 			= number,
			protocol 	= string
		})),
		ingress = list(object({
			description = string,
			cidr 		= string,
			from 		= number,
			to 			= number,
			protocol 	= string
		}))
    })
}