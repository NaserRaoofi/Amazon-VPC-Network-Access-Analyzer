# Amazon-VPC-Network-Access-Analyzer
Amazon VPC Network Access Analyzer
![dd](https://github.com/user-attachments/assets/5bb88de5-4e52-4587-b96c-a5a0b66dd393)

## Overview
This project demonstrates the use of **Amazon VPC Network Access Analyzer** to understand, verify, and improve network security posture in AWS. The lab environment consists of **three VPCs (vpc1, vpc2, and vpc3)**, each containing **EC2 instances, subnets, route tables, NACLs, and security groups**.

The main tasks completed in this lab include:
- **Creating an S3 Gateway Endpoint** in `vpc1`
- **Establishing a VPC Peering Connection** between `vpc1` and `vpc3`
- **Exploring pre-configured network resources** in the AWS environment

## Objectives
By completing this project, you will:
- Understand the architecture and networking elements in a multi-VPC setup.
- Implement an **S3 Gateway Endpoint** for private access to S3 from `vpc1`.
- Configure **VPC Peering** to allow secure communication between `vpc1` and `vpc3`.

## Architecture Diagram
The lab environment consists of the following AWS resources:
- **VPCs:** `vpc1`, `vpc2`, `vpc3`
- **Subnets:**
  - `vpc1-PRIVATE-subnet`
  - `vpc2-PRIVATE-subnet`
  - `vpc2-PUBLIC-subnet`
  - `vpc3-PUBLIC-subnet`
- **Route Tables:**
  - `vpc1-PRIVATE-RouteTable`
  - `vpc2-PRIVATE-RouteTable`
  - `vpc2-PUBLIC-RouteTable`
  - `vpc3-PUBLIC-RouteTable`
- **Internet Gateways:**
  - `vpc2-internet-gateway`
  - `vpc3-internet-gateway`
- **NAT Gateway:**
  - `vpc2-NatGateway-for-PrivateSubnet`
- **S3 Gateway Endpoint:**
  - Created in `vpc1`
- **VPC Peering Connection:**
  - Established between `vpc1` and `vpc3`

## Implementation Details
### 1️⃣ **Creating an S3 Gateway Endpoint in `vpc1`**
- Created an **S3 Gateway Endpoint** in `vpc1` to enable private access to S3 without using the internet.
- Associated it with the **Private Route Table** of `vpc1`.
- Verified S3 access from an EC2 instance in `vpc1` using the command:
  ```sh
  aws s3 ls s3://your-bucket-name --region your-region
  ```

### 2️⃣ **Establishing a VPC Peering Connection Between `vpc1` and `vpc3`**
- Created a **VPC Peering Connection** between `vpc1` and `vpc3`.
- Accepted the Peering Connection from `vpc3`.
- Updated the **Route Tables** in both VPCs to allow cross-VPC communication.
- Modified **Security Groups** to permit necessary traffic between instances in `vpc1` and `vpc3`.
- Verified connectivity using:
  ```sh
  ping <EC2-IP-in-vpc3>
  ```

## Verification & Testing
✅ **S3 Access Test:** Confirmed private access to S3 from an EC2 instance in `vpc1` using the **S3 Gateway Endpoint**.
✅ **Cross-VPC Connectivity Test:** Verified network connectivity between `vpc1` and `vpc3` via **VPC Peering**.
✅ **Security Group and Route Table Validation:** Ensured that security groups and route tables allowed necessary traffic between VPCs.

## Conclusion
This project successfully demonstrated how to **enhance network security and connectivity** using AWS VPC Network Access Analyzer. By implementing an **S3 Gateway Endpoint** and **VPC Peering**, we achieved:
- **Private access to S3** without an internet gateway.
- **Secure VPC communication** without a transit gateway.
- **Improved network visibility and compliance validation** using AWS Network Access Analyzer.


