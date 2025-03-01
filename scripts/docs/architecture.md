# Network Architecture Documentation

## Overview
This project implements a secure multi-VPC network architecture using AWS CloudFormation.

## Network Components

### VPC Architecture
- **VPC1**: Private VPC for secure workloads
  - CIDR: 10.0.0.0/16
  - Private subnets only
  - No direct internet access

- **VPC2**: Transit VPC
  - CIDR: 10.1.0.0/16
  - Public and private subnets
  - NAT Gateway for private subnet access
  - Internet Gateway for public access

- **VPC3**: Public-facing VPC
  - CIDR: 10.2.0.0/16
  - Public subnets
  - Internet Gateway

### Routing Configuration
1. Private Route Tables
   - Internal VPC routing
   - NAT Gateway routes
   
2. Public Route Tables
   - Internet Gateway routes
   - VPC peering routes

### Security
1. Network ACLs
2. Security Groups
3. VPC Flow Logs

## Network Flow Diagrams
[See diagrams/network-flow.png for visual representation]

## Implementation Details
All resources are deployed using CloudFormation templates located in the `templates/` directory. 