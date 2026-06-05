import sys
import boto3
from botocore.exceptions import BotoCoreError, ClientError

def test_aws_infrastructure(region="us-east-1"):
    print(f"=== Starting AWS Infrastructure Checks in region {region} ===")
    
    ec2 = boto3.client('ec2', region_name=region)
    success = True

    # 1. Check VPC
    try:
        vpcs = ec2.describe_vpcs(Filters=[{'Name': 'tag:Name', 'Values': ['vpc-devops', 'Devops-VPC']}])
        if vpcs['Vpcs']:
            vpc_id = None
            vpc_cidr = None
            for v in vpcs['Vpcs']:
                instances = ec2.describe_instances(Filters=[
                    {'Name': 'vpc-id', 'Values': [v['VpcId']]},
                    {'Name': 'tag:Name', 'Values': ['public-ec2-devops', 'Devops-Public-EC2']}
                ])
                if any(r['Instances'] for r in instances['Reservations']):
                    vpc_id = v['VpcId']
                    vpc_cidr = v['CidrBlock']
                    break
            
            if not vpc_id:
                vpc_id = vpcs['Vpcs'][0]['VpcId']
                vpc_cidr = vpcs['Vpcs'][0]['CidrBlock']
                
            print(f"[OK] VPC found: {vpc_id} (CIDR: {vpc_cidr})")
        else:
            print("[FAIL] Could not find VPC with tag Name 'vpc-devops' or 'Devops-VPC'")
            success = False
            return False
    except (BotoCoreError, ClientError) as e:
        print(f"[ERROR] Error querying VPC: {e}")
        return False

    # 2. Check Subnets
    try:
        subnets = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
        sub_list = subnets['Subnets']
        public_sub = []
        private_sub = []
        for s in sub_list:
            name_tag = next((t.get('Value', '') for t in s.get('Tags', []) if t.get('Key') == 'Name'), '')
            if 'public' in name_tag.lower():
                public_sub.append(s)
            elif 'private' in name_tag.lower():
                private_sub.append(s)
        
        if public_sub:
            print(f"[OK] Public Subnet found: {public_sub[0]['SubnetId']} (CIDR: {public_sub[0]['CidrBlock']})")
        else:
            print("[FAIL] Public Subnet missing")
            success = False
            
        if private_sub:
            print(f"[OK] Private Subnet found: {private_sub[0]['SubnetId']} (CIDR: {private_sub[0]['CidrBlock']})")
        else:
            print("[FAIL] Private Subnet missing")
            success = False
    except Exception as e:
        print(f"[ERROR] Error querying Subnets: {e}")
        success = False

    # 3. Check Internet Gateway
    try:
        igws = ec2.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])
        if igws['InternetGateways']:
            print(f"[OK] Internet Gateway attached: {igws['InternetGateways'][0]['InternetGatewayId']}")
        else:
            print("[FAIL] Internet Gateway attached to VPC not found")
            success = False
    except Exception as e:
        print(f"[ERROR] Error querying IGW: {e}")
        success = False

    # 4. Check NAT Gateway
    try:
        nat_gws = ec2.describe_nat_gateways(Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_id]},
            {'Name': 'state', 'Values': ['available', 'pending']}
        ])
        if nat_gws['NatGateways']:
            nat_gw = nat_gws['NatGateways'][0]
            print(f"[OK] NAT Gateway active: {nat_gw['NatGatewayId']} (Subnet: {nat_gw['SubnetId']}, State: {nat_gw['State']})")
        else:
            print("[FAIL] Active NAT Gateway not found")
            success = False
    except Exception as e:
        print(f"[ERROR] Error querying NAT Gateway: {e}")
        success = False

    # 5. Check Security Groups
    try:
        sgs = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
        public_sg = [sg for sg in sgs['SecurityGroups'] if 'public' in sg['GroupName'].lower()]
        private_sg = [sg for sg in sgs['SecurityGroups'] if 'private' in sg['GroupName'].lower()]
        
        if public_sg:
            print(f"[OK] Public Security Group found: {public_sg[0]['GroupId']}")
            ssh_allowed = any(
                perm.get('FromPort') == 22 and perm.get('ToPort') == 22
                for perm in public_sg[0]['IpPermissions']
            )
            if ssh_allowed:
                print(f"     -> [OK] SSH (Port 22) is allowed")
            else:
                print(f"     -> [WARNING] SSH Port 22 configuration not found")
        else:
            print("[FAIL] Public Security Group missing")
            success = False

        if private_sg:
            print(f"[OK] Private Security Group found: {private_sg[0]['GroupId']}")
        else:
            print("[FAIL] Private Security Group missing")
            success = False
    except Exception as e:
        print(f"[ERROR] Error querying Security Groups: {e}")
        success = False

    # 6. Check EC2 Instances
    try:
        instances = ec2.describe_instances(Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_id]},
            {'Name': 'instance-state-name', 'Values': ['running', 'pending', 'stopped']}
        ])
        inst_list = []
        for r in instances['Reservations']:
            inst_list.extend(r['Instances'])
            
        public_ec2 = []
        private_ec2 = []
        for i in inst_list:
            name_tag = next((t.get('Value', '') for t in i.get('Tags', []) if t.get('Key') == 'Name'), '')
            if 'public' in name_tag.lower():
                public_ec2.append(i)
            elif 'private' in name_tag.lower():
                private_ec2.append(i)
        
        if public_ec2:
            print(f"[OK] Public EC2 Instance found: {public_ec2[0]['InstanceId']} (State: {public_ec2[0]['State']['Name']}, IP: {public_ec2[0].get('PublicIpAddress', 'None')})")
        else:
            print("[FAIL] Public EC2 Instance missing")
            success = False
            
        if private_ec2:
            print(f"[OK] Private EC2 Instance found: {private_ec2[0]['InstanceId']} (State: {private_ec2[0]['State']['Name']}, IP: {private_ec2[0].get('PrivateIpAddress', 'None')})")
        else:
            print("[FAIL] Private EC2 Instance missing")
            success = False
    except Exception as e:
        print(f"[ERROR] Error querying EC2 Instances: {e}")
        success = False

    print("\n=== VERIFICATION RESULTS ===")
    if success:
        print("[SUCCESS] All resources are correctly configured according to Lab 1 requirements!")
        return True
    else:
        print("[FAILED] Some resources are missing or incorrectly configured.")
        return False

if __name__ == "__main__":
    test_aws_infrastructure()
