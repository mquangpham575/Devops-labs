import sys
import boto3
from botocore.exceptions import BotoCoreError, ClientError

def test_aws_infrastructure(region="us-east-1"):
    print(f"=== Bắt đầu kiểm tra hạ tầng AWS tại region {region} ===")
    
    ec2 = boto3.client('ec2', region_name=region)
    success = True

    # 1. Kiểm tra VPC
    try:
        vpcs = ec2.describe_vpcs(Filters=[{'Name': 'tag:Name', 'Values': ['vpc-devops', 'Devops-VPC']}])
        if vpcs['Vpcs']:
            vpc_id = vpcs['Vpcs'][0]['VpcId']
            print(f"[OK] VPC tìm thấy: {vpc_id} (CIDR: {vpcs['Vpcs'][0]['CidrBlock']})")
        else:
            print("[FAIL] Không tìm thấy VPC với tag Name 'vpc-devops' hoặc 'Devops-VPC'")
            success = False
            return False
    except (BotoCoreError, ClientError) as e:
        print(f"[ERROR] Lỗi truy vấn VPC: {e}")
        return False

    # 2. Kiểm tra Subnets
    try:
        subnets = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
        sub_list = subnets['Subnets']
        public_sub = [s for s in sub_list if 'public' in s.get('Tags', [{}])[0].get('Value', '').lower()]
        private_sub = [s for s in sub_list if 'private' in s.get('Tags', [{}])[0].get('Value', '').lower()]
        
        if public_sub:
            print(f"[OK] Public Subnet tìm thấy: {public_sub[0]['SubnetId']} (CIDR: {public_sub[0]['CidrBlock']})")
        else:
            print("[FAIL] Thiếu Public Subnet")
            success = False
            
        if private_sub:
            print(f"[OK] Private Subnet tìm thấy: {private_sub[0]['SubnetId']} (CIDR: {private_sub[0]['CidrBlock']})")
        else:
            print("[FAIL] Thiếu Private Subnet")
            success = False
    except Exception as e:
        print(f"[ERROR] Lỗi truy vấn Subnets: {e}")
        success = False

    # 3. Kiểm tra Internet Gateway
    try:
        igws = ec2.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])
        if igws['InternetGateways']:
            print(f"[OK] Internet Gateway attached: {igws['InternetGateways'][0]['InternetGatewayId']}")
        else:
            print("[FAIL] Không tìm thấy Internet Gateway attached với VPC")
            success = False
    except Exception as e:
        print(f"[ERROR] Lỗi truy vấn IGW: {e}")
        success = False

    # 4. Kiểm tra NAT Gateway
    try:
        nat_gws = ec2.describe_nat_gateways(Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_id]},
            {'Name': 'state', 'Values': ['available', 'pending']}
        ])
        if nat_gws['NatGateways']:
            nat_gw = nat_gws['NatGateways'][0]
            print(f"[OK] NAT Gateway hoạt động: {nat_gw['NatGatewayId']} (Subnet: {nat_gw['SubnetId']}, State: {nat_gw['State']})")
        else:
            print("[FAIL] Không tìm thấy NAT Gateway đang hoạt động")
            success = False
    except Exception as e:
        print(f"[ERROR] Lỗi truy vấn NAT Gateway: {e}")
        success = False

    # 5. Kiểm tra Security Groups
    try:
        sgs = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
        public_sg = [sg for sg in sgs['SecurityGroups'] if 'public' in sg['GroupName'].lower()]
        private_sg = [sg for sg in sgs['SecurityGroups'] if 'private' in sg['GroupName'].lower()]
        
        if public_sg:
            print(f"[OK] Public Security Group tìm thấy: {public_sg[0]['GroupId']}")
            # Check SSH port 22 configuration
            ssh_allowed = any(
                perm.get('FromPort') == 22 and perm.get('ToPort') == 22
                for perm in public_sg[0]['IpPermissions']
            )
            if ssh_allowed:
                print(f"     -> [OK] Cho phép SSH (Port 22)")
            else:
                print(f"     -> [WARNING] Chưa có cấu hình mở port 22 cho SSH")
        else:
            print("[FAIL] Thiếu Public Security Group")
            success = False

        if private_sg:
            print(f"[OK] Private Security Group tìm thấy: {private_sg[0]['GroupId']}")
        else:
            print("[FAIL] Thiếu Private Security Group")
            success = False
    except Exception as e:
        print(f"[ERROR] Lỗi truy vấn Security Groups: {e}")
        success = False

    # 6. Kiểm tra EC2 Instances
    try:
        instances = ec2.describe_instances(Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_id]},
            {'Name': 'instance-state-name', 'Values': ['running', 'pending', 'stopped']}
        ])
        inst_list = []
        for r in instances['Reservations']:
            inst_list.extend(r['Instances'])
            
        public_ec2 = [i for i in inst_list if 'public' in i.get('Tags', [{}])[0].get('Value', '').lower()]
        private_ec2 = [i for i in inst_list if 'private' in i.get('Tags', [{}])[0].get('Value', '').lower()]
        
        if public_ec2:
            print(f"[OK] Public EC2 Instance tìm thấy: {public_ec2[0]['InstanceId']} (State: {public_ec2[0]['State']['Name']}, IP: {public_ec2[0].get('PublicIpAddress', 'None')})")
        else:
            print("[FAIL] Thiếu Public EC2 Instance")
            success = False
            
        if private_ec2:
            print(f"[OK] Private EC2 Instance tìm thấy: {private_ec2[0]['InstanceId']} (State: {private_ec2[0]['State']['Name']}, IP: {private_ec2[0].get('PrivateIpAddress', 'None')})")
        else:
            print("[FAIL] Thiếu Private EC2 Instance")
            success = False
    except Exception as e:
        print(f"[ERROR] Lỗi truy vấn EC2 Instances: {e}")
        success = False

    print("\n=== KẾT QUẢ KIỂM TRA ===")
    if success:
        print("[SUCCESS] Tất cả dịch vụ được cấu hình chính xác theo đặc tả của Lab 1!")
        return True
    else:
        print("[FAILED] Một số dịch vụ chưa được cấu hình hoặc cấu hình sai.")
        return False

if __name__ == "__main__":
    test_aws_infrastructure()
