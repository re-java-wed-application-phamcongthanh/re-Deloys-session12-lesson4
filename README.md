# Bài 4: Tự Động Triển Khai Ứng Dụng Spring Boot (Container) Lên VPS Từ Xa Qua SSH

## 🎯 1. Mục Tiêu
- Xây dựng luồng Continuous Deployment (CD) hoàn chỉnh từ khâu đóng gói Docker Image đến khâu triển khai tự động lên máy chủ VPS từ xa qua giao thức bảo mật SSH.
- Sử dụng action `appleboy/ssh-action@v1.0.3` để tự động xác thực và thực thi câu lệnh điều phối Docker container trên VPS.
- Quản lý thông tin máy chủ nhạy cảm bằng **GitHub Repository Secrets** (`SSH_HOST`, `SSH_USER`, `SSH_KEY`).

---

## 📁 2. Cấu Trúc Thư Mục
```text
bai4/
├── .github/
│   └── workflows/
│       └── deploy-vps.yml       # Kịch bản CI/CD Build & SSH Deployment
├── .dockerignore
├── Dockerfile                   # Đóng gói ứng dụng cổng 8080 kèm /actuator/health
├── index.html                   # Giao diện ứng dụng web
└── README.md                    # Tài liệu hướng dẫn cấu hình & kiểm thử
```

---

## ⚙️ 3. Kịch Bản Workflow CI/CD (`.github/workflows/deploy-vps.yml`)

```yaml
name: Build & Remote VPS Deployment via SSH

on:
  push:
    branches: [ "main" ]

jobs:
  build-image:
    name: Build & Push Docker Image
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout mã nguồn
        uses: actions/checkout@v5

      - name: Đăng nhập vào GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Đóng gói và đẩy Docker Image lên GHCR
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.actor }}/my-app:latest

  deploy-vps:
    name: Deploy Container to Remote VPS via SSH
    needs: build-image
    runs-on: ubuntu-latest

    steps:
      - name: Thực thi câu lệnh triển khai trên VPS qua SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            echo "Kéo Docker Image mới nhất từ GHCR..."
            docker pull ghcr.io/${{ github.actor }}/my-app:latest
            
            echo "Dừng và xóa container cũ nếu đang chạy..."
            docker stop my-app || true
            docker rm my-app || true
            
            echo "Khởi chạy container mới lắng nghe trên cổng 8080..."
            docker run -d --name my-app -p 8080:8080 ghcr.io/${{ github.actor }}/my-app:latest
            
            echo "Kiểm tra trạng thái container:"
            docker ps --filter "name=my-app"
```

---

## 🔐 4. Hướng Dẫn Cấu Hình Secrets Trên GitHub

Truy cập **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret** trên repository:

| Tên Secret | Ý nghĩa | Ví dụ giá trị |
| :--- | :--- | :--- |
| `SSH_HOST` | Địa chỉ IP công khai hoặc tên miền của máy chủ VPS | `103.x.x.x` hoặc `vps.example.com` |
| `SSH_USER` | Tên người dùng quản trị SSH trên VPS | `ubuntu` hoặc `root` |
| `SSH_KEY` | Toàn bộ nội dung của SSH Private Key (bao gồm cả dòng `-----BEGIN OPENSSH PRIVATE KEY-----` và `-----END OPENSSH PRIVATE KEY-----`) | Khóa cá nhân từ máy tính |

> **Lưu ý cấu hình SSH Key trên VPS**:
> Đảm bảo SSH Public Key tương ứng đã được thêm vào tệp `~/.ssh/authorized_keys` trên máy chủ VPS:
> ```bash
> cat id_rsa.pub >> ~/.ssh/authorized_keys
> chmod 600 ~/.ssh/authorized_keys
> chmod 700 ~/.ssh
> ```

---

## 🔍 5. Kiểm Tra & Xác Nhận Kết Quả

1. **Đẩy mã nguồn lên nhánh `main`**:
   ```bash
   git add .
   git commit -m "feat: complete session 12 exercise 4 with deploy-vps.yml and Dockerfile"
   git push origin main
   ```
2. **Kiểm tra tab Actions**:
   - Job `build-image` hoàn thành xuất bản image `ghcr.io/<actor>/my-app:latest`.
   - Job `deploy-vps` tự động kết nối qua SSH vào VPS, kéo image mới và khởi chạy lại container `my-app` tại port 8080.
3. **Kiểm tra ứng dụng trên trình duyệt / curl**:
   - Truy cập URL kiểm tra sức khỏe ứng dụng:
     ```bash
     curl http://<VPS_IP>:8080/actuator/health
     ```
   - **Kết quả mong đợi**: Mã phản hồi `HTTP/1.1 200 OK` và chuỗi JSON:
     ```json
     {"status":"UP"}
     ```
   - Truy cập `http://<VPS_IP>:8080/` hiển thị trang chủ chào mừng của ứng dụng đã deploy.
