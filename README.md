# Hướng dẫn Cài đặt, Triển khai và Kiểm tra Hạ tầng DevOps (Lab 1 & Lab 2)

Dự án này tích hợp và triển khai tự động hóa hạ tầng đám mây trên AWS bằng công nghệ IaC (Terraform và CloudFormation), thiết lập môi trường ứng dụng microservices chạy trên cụm K3s (Kubernetes tối giản) tại EC2 instance, đồng thời xây dựng quy trình CI/CD hoàn chỉnh (tích hợp các tác vụ quét chất lượng mã nguồn tĩnh, kiểm thử bảo mật và tự động hóa triển khai thông qua AWS CodePipeline và GitHub Actions).

---

## 1. Kiến trúc Hệ thống & Tham số Hạ tầng

Mã nguồn triển khai hạ tầng mạng trên AWS tuân thủ cấu trúc bảo mật phân vùng mạng như sau:

| Thành phần | Triển khai Terraform (Lab 1 / Lab 2 - Part 1) | Triển khai CloudFormation (Lab 2 - Part 2) |
| :--- | :--- | :--- |
| **VPC CIDR** | `10.0.0.0/16` | `10.0.0.0/16` |
| **Public Subnet** | `10.0.0.0/24` | `10.0.0.0/24` |
| **Private Subnet** | `10.0.1.0/24` | `10.0.10.0/24` |
| **Public EC2 IP (Private)** | `10.0.0.4` | `10.0.0.4` |
| **Private EC2 IP (Private)** | `10.0.1.8` | `10.0.10.8` |
| **Hệ điều hành EC2** | Ubuntu 22.04 LTS | Amazon Linux 2023 |
| **NAT Gateway** | Khởi tạo trên Public Subnet để Private Subnet đi ra ngoài internet tải tài nguyên. |

### Minh họa tài nguyên thực tế trên AWS Console:
*   **VPC List:**
    ![VPC List](images/vpc.png)
*   **Route Tables:**
    ![Route Tables](images/route_tables.png)
*   **NAT Gateway & Elastic IP:**
    ![NAT Gateways](images/nat_gateways.png)
*   **EC2 Instances:**
    ![EC2 Instances](images/ec2_instances.png)

### Cơ chế bảo mật (Security Groups):
*   **Public Security Group:** Cho phép truy cập SSH (Port 22), Ping (ICMP) từ dải mạng được cấu hình (mặc định mở rộng `0.0.0.0/0` hoặc IP tĩnh của người dùng để GitHub Actions kết nối), mở Port 80 (HTTP) và Port 30000 (NodePort) phục vụ truy cập ứng dụng.
*   **Private Security Group:** Chỉ chấp nhận lưu lượng inbound (SSH/ICMP) từ chính Security Group của Public EC2 (Referenced Security Group). Ngăn chặn hoàn toàn truy cập trực tiếp từ môi trường Internet.

---

## 2. Chuẩn bị Môi trường Cục bộ (Prerequisites)

Để thiết lập môi trường chạy thử và quản lý cục bộ, hãy cài đặt các công cụ sau:

1.  **Terraform (v1.5.0+):** Dùng để quản lý, lập kế hoạch và áp dụng hạ tầng IaC.
2.  **AWS CLI v2:** Cấu hình tài khoản AWS để thực thi các lệnh IaC cục bộ.
3.  **Python (v3.11+):** Chạy script kiểm thử hạ tầng tự động (`tests/test_infra.py`).
4.  **Pip & Thư viện Python:** Cài đặt các gói phụ phụ thuộc:
    ```bash
    pip install boto3 cfn-lint taskcat
    ```
5.  **Git:** Đồng bộ mã nguồn lên kho chứa GitHub để kích hoạt các pipeline CI/CD.

### Cấu hình AWS Credentials
Khi sử dụng tài khoản **AWS Academy**, thông tin xác thực (Access Key, Secret Key, Session Token) thay đổi theo từng phiên làm việc. Hãy cập nhật các thông tin này vào file cấu hình AWS CLI:
*   **Linux/macOS:** `~/.aws/credentials`
*   **Windows:** `C:\Users\<Tên_User>\.aws\credentials`

Nội dung cấu hình mẫu:
```ini
[default]
aws_access_key_id = ASIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
aws_session_token = IQoJb3JpZ2luX2VjEOb//////////wEaCXVzLWVhc3QtMS...
```

---

## 3. Quy trình Triển khai Hạ tầng IaC

### 3.1. Triển khai Hạ tầng bằng Terraform (Lab 1 & Lab 2 Part 1)

#### Cách chạy thủ công cục bộ:
1.  Di chuyển vào thư mục Terraform:
    ```bash
    cd terraform
    ```
2.  Khởi tạo các plugin nhà cung cấp và cấu hình backend (lưu trữ trạng thái từ xa trên S3):
    ```bash
    terraform init
    ```
    *(Lưu ý: Backend S3 cấu hình tại [main.tf](./terraform/main.tf) sử dụng bucket `mquangpham575-tfstate`).*
3.  Kiểm tra và xác thực kế hoạch triển khai:
    ```bash
    terraform plan
    ```
4.  Áp dụng triển khai tài nguyên lên AWS:
    ```bash
    terraform apply -auto-approve
    ```
5.  Dọn dẹp hạ tầng khi không sử dụng:
    ```bash
    terraform destroy -auto-approve
    ```

#### Tự động hóa qua GitHub Actions (`.github/workflows/action.yaml`):
*   **Trình kích hoạt:** Tự động kích hoạt khi có thay đổi được push vào thư mục `terraform/**`.
*   **Giai đoạn Kiểm thử bảo mật (Job `test`):** Sử dụng công cụ **Checkov** để quét tĩnh mã nguồn Terraform, kiểm tra các vi phạm bảo mật (như mở cổng SSH công cộng hoặc thiếu mã hóa ổ đĩa).
    *   *Minh chứng quét Checkov:*
        ![Checkov Security Scan Results](images/checkov_scan.png)
*   **Giai đoạn Triển khai (Job `deploy`):** Tự động cấu hình AWS credentials và thực thi `terraform apply -auto-approve` để đồng bộ hạ tầng lên Cloud.
    *   *Minh chứng Pipeline Terraform:*
        ![Terraform CI/CD Workflow](images/terraform_pipeline.png)

---

### 3.2. Triển khai Hạ tầng bằng CloudFormation & AWS CodePipeline (Lab 2 Part 2)

Hạ tầng CloudFormation được quản lý tập trung và triển khai tự động hóa thông qua quy trình CI/CD chuẩn AWS:

#### 1. Quản lý mã nguồn trên AWS CodeCommit:
Toàn bộ mã nguồn và template CloudFormation (trong thư mục `cloudformation/`) được lưu trữ và quản lý tập trung trên một repository riêng biệt của dịch vụ AWS CodeCommit. Quy trình CI/CD sẽ tự động kích hoạt mỗi khi có thay đổi được push lên nhánh chính `main` của repository này.

#### 2. Quy trình CI/CD với AWS CodePipeline:
Pipeline tự động hóa hoàn toàn quy trình kiểm thử và triển khai hạ tầng bao gồm các Stage chính:
*   **Source Stage:** AWS CodePipeline tự động giám sát repository CodeCommit và tải về mã nguồn IaC mới nhất khi có commit mới.
    *   *Minh chứng cấu hình Source Stage:*
        ![Cấu hình Source CodeCommit](images/codepipeline_config_part1.png)
*   **Build Stage:** Khởi chạy AWS CodeBuild sử dụng một Service Role riêng biệt tên là `codebuild-Devops-lab-aws-build-service-role` (được cấp các quyền truy cập cần thiết vào hạ tầng AWS và các S3 buckets phục vụ Taskcat).
    *   *Minh chứng cấu hình Build & Deploy Stage:*
        ![Cấu hình Build & Deploy CodePipeline](images/codepipeline_config_part2.png)
    *   *Minh chứng cấu hình phân quyền Service Role cho AWS CodeBuild:*
        ![Cấu hình phân quyền Service Role cho AWS CodeBuild](images/codebuild_role.png)
    *   **Trong môi trường CodeBuild:**
        *   Thực hiện quét tĩnh cú pháp và lỗi định dạng template với `cfn-lint`.
        *   Khởi chạy kiểm thử tích hợp thực tế đa vùng (multi-region integration testing) với `taskcat` để đảm bảo hạ tầng có khả năng khởi tạo thành công trên môi trường thật.
        *   Triển khai/cập nhật hạ tầng CloudFormation Stack thực tế lên tài khoản AWS thông qua dịch vụ CloudFormation.
        *   *Minh chứng nhật ký chạy cfn-lint và taskcat trong AWS CodeBuild:*
            ![Nhật ký chạy cfn-lint và taskcat trong AWS CodeBuild](images/codebuild_logs.png)

#### 3. Kết quả chạy Pipeline và Stack:
*   **Trạng thái CodePipeline chạy thành công:**
    ![Trạng thái AWS CodePipeline chạy thành công](images/codepipeline_success.png)
*   **Trạng thái Stack được tạo thành công (CREATE_COMPLETE):**
    ![Trạng thái Stack trên AWS Console](images/cfn_stack.png)
*   **Danh sách tài nguyên CloudFormation Stack được tạo thành công:**
    ![Danh sách tài nguyên CloudFormation Stack](images/cfn_stack_resources.png)


#### Phân tích quy trình CI/CD CloudFormation:
Sự kết hợp giữa CodeCommit, CodePipeline và CodeBuild tạo nên một quy trình DevSecOps khép kín hoàn chỉnh chuẩn AWS. Việc gán Service Role chuyên biệt `codebuild-Devops-lab-aws-build-service-role` giúp kiểm soát chặt chẽ quyền hạn thực thi (Least Privilege) của CodeBuild/Taskcat khi tương tác với tài nguyên cloud.

---

> **LƯU Ý VỀ GIẢI PHÁP DỰ PHÒNG QUA GITHUB ACTIONS:**
> Trong trường hợp tài khoản sandbox AWS Academy bị giới hạn quyền SCP gây khó khăn cho việc quản lý các dự án CodeBuild trực tiếp từ Terraform, dự án cũng cung cấp một workflow GitHub Actions dự phòng qua file cấu hình [.github/workflows/deploy-cfn.yml](./.github/workflows/deploy-cfn.yml) chạy các tác vụ `cfn-lint`, `taskcat` và tự động deploy Stack lên AWS tương đương.
> *   *Minh chứng Pipeline CloudFormation dự phòng trên GitHub Actions:*
>       ![CloudFormation CI/CD Workflow trên GitHub Actions](images/cfn_pipeline.png)
> *   *Minh chứng logs cfn-lint & taskcat trong GitHub Actions:*
>       ![cfn-lint and taskcat Validation Logs](images/cfn_logs.png)

---

## 4. Thiết lập quy trình CI/CD cho Microservices (Lab 2 Part 3)

Ứng dụng Node.js microservice nằm tại [microservices/app/](./microservices/app/) được tự động đóng gói, kiểm tra chất lượng và deploy vào cụm K3s trên Public EC2.

### 4.1. Thiết lập GitHub Repository Secrets
Để pipeline chạy thành công, hãy truy cập vào mục cài đặt của Repository (Settings > Secrets and variables > Actions) và thêm đầy đủ các biến bảo mật sau:

| Tên Secret | Ý nghĩa & Giá trị mẫu |
| :--- | :--- |
| `AWS_ACCESS_KEY_ID` | Access Key ID lấy từ AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Secret Access Key lấy từ AWS Academy |
| `AWS_SESSION_TOKEN` | Session Token tạm thời của AWS Academy |
| `EC2_HOST` | IP công cộng của Public EC2 vừa được tạo (ví dụ: `54.198.66.34`) |
| `EC2_SSH_KEY` | Toàn bộ nội dung của file key private [labsuser.pem](./labsuser.pem) |
| `DOCKER_HUB_USERNAME` | Tên tài khoản Docker Hub của bạn |
| `DOCKER_HUB_TOKEN` | Access Token của tài khoản Docker Hub (dùng để push image) |
| `SONAR_TOKEN` | Token xác thực lấy từ tài khoản SonarCloud |

---

### 4.2. Chi tiết luồng hoạt động của Pipeline (`.github/workflows/deploy-app.yml`)

Mỗi khi có thay đổi trong thư mục `microservices/**` được đẩy lên GitHub, pipeline sẽ kích hoạt 2 Job liên tiếp:

#### 1. Job `build-and-test`:
*   **Build & Unit Test:** Cài đặt Node.js v20, khôi phục thư viện và chạy các test case.
*   **SonarCloud Quality Scan:** Quét chất lượng mã nguồn tĩnh (phân tích lỗi logic, lỗ hổng bảo mật tiềm ẩn, code smells) thông qua file cấu hình [sonar-project.properties](./sonar-project.properties).
    *   *Minh chứng kết quả quét SonarCloud:*
        ![SonarCloud Analysis Passed](images/sonarcloud.png)
*   **Trivy Vulnerability Scan:** Quét lỗi bảo mật thư viện phụ thuộc trực tiếp trên mã nguồn hệ thống (`fs` scan).
    *   *Minh chứng kết quả quét Trivy:*
        ![Trivy Vulnerability Scanner Logs](images/trivy_scan.png)
*   **Docker Publish:** Đóng gói ứng dụng NodeJS thành Docker Image và tự động push lên Docker Hub cá nhân với tag `latest` và tag ứng với số phiên chạy `run_number`.
    *   *Minh chứng đẩy Docker Hub thành công:*
        ![Docker Hub Repositories](images/docker_hub.png)

#### 2. Job `deploy` (Kết nối SSH trực tiếp vào Public EC2):
*   **Khởi tạo Docker:** Kiểm tra sự tồn tại của Docker trên máy ảo, cài đặt tự động nếu thiếu.
*   **Khởi tạo K3s Cluster:** Cài đặt cụm Kubernetes gọn nhẹ (K3s), cấp quyền tệp cấu hình `k3s.yaml` để cho phép thao tác cluster.
*   **Thiết lập Swap Space (Phòng tránh OOM):**
    > **CẢNH BÁO VỀ GIỚI HẠN TÀI NGUYÊN EC2:**
    > Do máy ảo `t3.micro` của AWS Academy chỉ có dung lượng RAM 1GB (thực tế trống khoảng 50MB - 100MB khi chạy hệ điều hành), cụm K3s và ứng dụng rất dễ bị crash/OOM. Pipeline tự động tạo **2 GiB Swap Space** trên ổ đĩa ảo để mở rộng RAM ảo, giúp cụm K3s hoạt động ổn định.
*   **Tạo Manifests động:** Tạo tệp `deployment.yaml` (2 bản sao container, cấu hình giới hạn tài nguyên CPU/RAM, tích hợp Liveness & Readiness Probes kiểm tra trạng thái container tại cổng 3000 đường dẫn `/health`) và `service.yaml` (kiểu LoadBalancer, ánh xạ Port 80 của host EC2 vào Port 3000 của ứng dụng).
*   **Rollout kiểm tra:** Áp dụng manifest qua `kubectl` và đợi trạng thái triển khai thành công (`rollout status` tối đa trong 60 giây).
    *   *Minh chứng Pipeline deploy Microservices:*
        ![Deploy Microservice Pipeline](images/microservice_pipeline.png)

---

## 5. Hướng dẫn Kiểm tra Kết quả Triển khai

### 5.1. Kiểm thử hạ tầng tự động (Python & Boto3)
Chạy script kiểm thử hạ tầng trực tiếp từ máy tính cá nhân của bạn (đảm bảo đã cấu hình AWS Credentials chính xác ở Mục 2):
```bash
python tests/test_infra.py
```
*Minh chứng kết quả chạy thành công script kiểm thử:*
![Test Infra Success](images/test_infra.png)

Kết quả mong đợi hiển thị đầy đủ thông tin xác thực trạng thái hạ tầng hoạt động:
```text
=== Starting AWS Infrastructure Checks in region us-east-1 ===
[OK] VPC found: vpc-0xxxxxxxxxxxxxxxx (CIDR: 10.0.0.0/16)
[OK] Public Subnet found: subnet-0xxxxxxxxxxxxxxxx (CIDR: 10.0.0.0/24)
[OK] Private Subnet found: subnet-0xxxxxxxxxxxxxxxx (CIDR: 10.0.1.0/24)
[OK] Internet Gateway attached: igw-0xxxxxxxxxxxxxxxx
[OK] NAT Gateway active: nat-0xxxxxxxxxxxxxxxx (Subnet: subnet-0xxxxxxxxxxxxxxxx, State: available)
[OK] Public Security Group found: sg-0xxxxxxxxxxxxxxxx
     -> [OK] SSH (Port 22) is allowed
[OK] Private Security Group found: sg-0xxxxxxxxxxxxxxxx
[OK] Public EC2 Instance found: i-0xxxxxxxxxxxxxxxx (State: running, IP: 54.198.66.34)
[OK] Private EC2 Instance found: i-0xxxxxxxxxxxxxxxx (State: running, IP: 10.0.1.8)

=== VERIFICATION RESULTS ===
[SUCCESS] All resources are correctly configured according to Lab 1 requirements!
```

---

### 5.2. Kiểm tra tài nguyên K3s trên máy ảo EC2
1.  SSH vào Public EC2 (Sử dụng khóa `labsuser.pem` và tài khoản `ubuntu`):
    ```bash
    ssh -i labsuser.pem ubuntu@<EC2_PUBLIC_IP>
    ```
2.  Kiểm tra trạng thái các Pod và Service chạy trong cụm K3s:
    ```bash
    sudo kubectl get all --kubeconfig /etc/rancher/k3s/k3s.yaml
    ```
    *Yêu cầu kết quả:*
    *   Cả 2 Pod ứng dụng Node.js (`devops-microservice-...`) phải ở trạng thái `Running`.
    *   Service `devops-microservice-service` phải ánh xạ thành công Port 80 sang TargetPort 3000 của các Pod.

---

### 5.3. Kiểm thử ứng dụng trên trình duyệt và API
Mở trình duyệt hoặc sử dụng công cụ dòng lệnh gửi request đến địa chỉ IP công cộng của Public EC2:

*   **Truy cập API trang chủ:**
    ```bash
    curl http://<EC2_PUBLIC_IP>/
    ```
    Kết quả phản hồi (JSON):
    ```json
    {
      "message": "Hello from DevOps Lab 2 Microservice!",
      "status": "healthy",
      "timestamp": "2026-06-06T06:55:00.000Z"
    }
    ```
*   **Truy cập API sức khỏe:**
    ```bash
    curl http://<EC2_PUBLIC_IP>/health
    ```
    Kết quả phản hồi (JSON):
    ```json
    {
      "status": "UP"
    }
    ```

---

### 5.4. Xác minh tính cách cô lập mạng của Private EC2
Để xác định tính bảo mật mạng của Private EC2 (được cấu hình qua Security Groups):
1.  Đăng nhập vào Public EC2 (`10.0.0.4`) bằng SSH.
2.  Từ Public EC2, thực hiện kết nối SSH hoặc ping tới Private EC2 sử dụng IP nội bộ:
    ```bash
    # Ping kiểm tra kết nối mạng nội bộ
    ping 10.0.1.8 (hoặc 10.0.10.8)
    
    # Kết nối SSH sang Private EC2 (cần copy private key labsuser.pem lên Public EC2 trước)
    ssh -i labsuser.pem ubuntu@10.0.1.8 (hoặc 10.0.10.8)
    ```
    *Kết quả:* Kết nối nội bộ từ Public EC2 sang Private EC2 thành công. Ngược lại, nếu thực hiện kết nối trực tiếp từ máy cá nhân ở bên ngoài internet tới IP của Private EC2, kết nối sẽ bị chặn hoàn toàn.
