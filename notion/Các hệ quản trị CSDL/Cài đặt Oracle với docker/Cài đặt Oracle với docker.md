# Cài đặt Oracle với docker

1. Có thể sử dụng Github Student để lấy 200USD Credit của Digital Ocean → mua droplet 8G RAM (VPS).
1. Cài đặt AlmaLinux 9
1. Cài đặt Docker
```Bash
# 1. Update hệ thống 
dnf update -y

# 2. Cài plugin repo
dnf install -y dnf-plugins-core

# 3. Thêm Docker repository
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 4. Cài Docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Start và enable Docker
systemctl start docker
systemctl enable docker

# 6. Kiểm tra & Test Docker
systemctl status docker
docker run hello-world
```

1. Cài Oracle
```Bash
# 1. Pull
docker pull gvenzl/oracle-xe:21-slim

# 2. Tạo Docker volume để lưu data
docker volume create oracle_demo_data
docker volume ls

# 3. Install 
docker run -d \
  --name oracle_demo \
  --restart unless-stopped \
  --memory=4g \
  --cpus=3 \
  -e ORACLE_PASSWORD=Hoadinh123 \
  -v oracle_demo_data:/opt/oracle/oradata \
  -p 1521:1521 \
  gvenzl/oracle-xe:21-slim
  
# 4. Kiểm tra container
docker ps
docker logs -f oracle_demo

# 5. Truy cập Oracle
docker exec -it oracle_demo sqlplus system/Hoadinh123@XEPDB1

# dnf install -y firewalld
# systemctl enable firewalld
# systemctl start firewalld
# systemctl status firewalld

# 6. Kiểm tra firewall AlmaLinux
firewall-cmd --zone=public --add-port=1521/tcp --permanent
```

1. Kết nối từ Visual Studio Code và test
1. Import dữ liệu
```Bash
# Trên máy host
git clone https://github.com/oracle/db-sample-schemas.git

# Copy vào container
docker cp db-sample-schemas oracle_demo:/opt/oracle/

# Chạy script tạo HR
docker exec -it oracle-xe bash
cd /opt/oracle/db-sample-schemas/human_resources

@hr_install.sql
```

1. Một số lệnh tiện ích
```Bash
# Stop and remove
docker stop oracle_demo
docker rm oracle_demo


# remove volume
docker volume rm oracle_demo_data
```

