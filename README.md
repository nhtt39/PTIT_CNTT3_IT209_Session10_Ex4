# Session 10 - Exercise 4: Docker Network & Volume

## 1. Mục tiêu

- Tạo Custom Bridge Network `app-net`.
- Tạo Named Volume `db-data`.
- Kết nối Backend và PostgreSQL bằng DNS nội bộ của Docker.
- Kiểm tra dữ liệu vẫn tồn tại sau khi xóa và tạo lại container database.

## 2. Cấu hình triển khai

### Custom Bridge Network

Sử dụng mạng `app-net` để kết nối hai container:

- `app-container`: Backend REST API.
- `db-server`: PostgreSQL 15 Alpine.

Backend kết nối database thông qua hostname `db-server`, cổng nội bộ `5432`, thay vì sử dụng địa chỉ IP cố định.

### Named Volume

Volume `db-data` được mount tại:

`/var/lib/postgresql/data`

Volume lưu trữ dữ liệu PostgreSQL độc lập với vòng đời container, giúp dữ liệu không bị mất khi xóa container database.

## 3. Script triển khai

File `commands.sh` tự động tạo network và volume, build Backend Image, chạy PostgreSQL và Backend, chèn dữ liệu kiểm thử, xóa container database, tạo lại container và truy vấn dữ liệu để xác minh tính bền vững.

Chạy script bằng:

```bash
chmod +x commands.sh
./commands.sh
```

## 4. Kết quả kiểm tra

### Network

```bash
docker network ls | grep app-net
docker network inspect app-net
```

Kết quả mong đợi: hai container cùng tham gia mạng `app-net`.

### Volume

```bash
docker volume ls | grep db-data
```

Kết quả mong đợi: volume `db-data` tồn tại sau khi container database được tạo lại.

### DNS nội bộ

```bash
docker exec -it app-container ping -c 2 db-server
```

Kết quả mong đợi: hostname `db-server` được phân giải thành IP nội bộ và nhận được phản hồi ping.

### Data Persistence

Dữ liệu được thêm vào bảng `persistence_test` trước khi xóa container `db-server`. Sau đó container được tạo lại với cùng volume `db-data`.

Truy vấn xác minh:

```bash
docker exec db-server psql -U appuser -d appdb -c "SELECT * FROM persistence_test;"
```

Kết quả mong đợi: bản ghi đã tạo trước đó vẫn còn nguyên vẹn.

### Backend API

```bash
curl -i http://localhost:8081/
```

Kết quả mong đợi: HTTP 200 OK và JSON xác nhận Backend kết nối thành công tới database `appdb`.

## 5. Kết luận

Đã thực hành tạo Custom Bridge Network, sử dụng DNS nội bộ để các container giao tiếp bằng tên, cấu hình Named Volume cho PostgreSQL và xác minh dữ liệu tồn tại sau khi tái tạo container database.
