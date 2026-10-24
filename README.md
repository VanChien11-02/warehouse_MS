# BlueStock - Hệ thống quản lý kho hàng

BlueStock là đồ án môn Hệ quản trị cơ sở dữ liệu (`DBMS330284`). Hệ thống quản lý danh mục hàng hóa, kho và vị trí; nhập, xuất, chuyển, kiểm kê, trả hàng; tồn kho theo lô; báo cáo, đối soát giá trị và nhật ký thao tác.

## Chức năng chính

- Đăng nhập bằng session và phân quyền theo bốn vai trò: `ADMIN`, `QLKHO`, `NVKHO`, `KETOAN`.
- Quản lý sản phẩm, loại sản phẩm, đơn vị tính, kho, khu vực, vị trí và đối tác.
- Lập, sửa, hủy và hoàn tất năm loại chứng từ: nhập, xuất, chuyển kho, kiểm kê và trả hàng.
- Quản lý tồn theo lô/vị trí, xuất theo FEFO và bảo vệ việc ghi sổ bằng transaction SQL Server.
- Báo cáo nhập–xuất–tồn, lô sắp hết hạn, chênh lệch kiểm kê và đối soát giá trị.
- Ghi nhật ký các thao tác quan trọng.

## Công nghệ

| Thành phần | Công nghệ |
| --- | --- |
| Frontend | HTML5, CSS3, Vanilla JavaScript, Fetch API |
| Backend | Java 21, Spring Boot 3.5, Spring Web, Spring Security, Spring JDBC/JPA |
| Database | Microsoft SQL Server 2022, T-SQL |
| Công cụ | Maven Wrapper, PowerShell 7, Node.js 22, Docker Compose |

Frontend có hai chế độ:

- `http://127.0.0.1:5174/`: prototype dùng dữ liệu mẫu.
- `http://127.0.0.1:5174/?mode=api`: chương trình kết nối API và database thật.

## Cài đặt và chạy chương trình

Có hai cách chạy. Docker Compose là cách nhanh và ổn định nhất để demo toàn bộ hệ thống. Cách cài trực tiếp phù hợp khi cần phát triển hoặc kiểm tra từng thành phần.

### Cách 1 - Chạy bằng Docker Compose (khuyến nghị)

#### Yêu cầu

- Git 2.40 trở lên.
- PowerShell 7 trở lên.
- Docker Desktop đang chạy ở chế độ Linux containers.

#### Bước 1: Lấy mã nguồn

```powershell
git clone <repository-url>
cd <repository-folder>
```

Nếu đã có mã nguồn, mở PowerShell tại thư mục gốc của repository.

#### Bước 2: Tạo cấu hình môi trường

```powershell
Copy-Item .env.example .env
```

Mở `.env` và điền ba mật khẩu khác nhau:

```dotenv
MSSQL_SA_PASSWORD=<mat-khau-sa-du-manh>
APP_DB_PASSWORD=<mat-khau-ket-noi-api>
APP_ADMIN_PASSWORD=<mat-khau-dang-nhap-admin>
```

Lưu ý:

- Mật khẩu SQL Server phải đáp ứng chính sách phức tạp của SQL Server.
- `APP_DB_PASSWORD` dài 12–64 ký tự và chỉ dùng chữ, số hoặc `@#%+=._!-`.
- `APP_ADMIN_PASSWORD` dài ít nhất 12 ký tự.
- Không commit hoặc chia sẻ file `.env`.

Các cổng mặc định đã có trong `.env.example`:

| Dịch vụ | Địa chỉ |
| --- | --- |
| Frontend | `http://127.0.0.1:5174` |
| Backend API | `http://127.0.0.1:8080` |
| SQL Server | `tcp:127.0.0.1,14330` |

#### Bước 3: Khởi động

```powershell
docker compose up -d --build
docker compose ps --all
```

Đợi đến khi:

- `db` có trạng thái `healthy`;
- `db-init` kết thúc với mã `0`;
- `api` và `web` có trạng thái `Up`.

Kiểm tra backend:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/actuator/health
```

Kết quả hợp lệ có `status` là `UP`.

#### Bước 4: Mở và đăng nhập

Mở [http://127.0.0.1:5174/?mode=api](http://127.0.0.1:5174/?mode=api), sau đó đăng nhập bằng:

- Tên đăng nhập: `admin`.
- Mật khẩu: giá trị `APP_ADMIN_PASSWORD` trong `.env`.

Compose chỉ tạo tài khoản admin khi bảng tài khoản còn trống. Việc sửa `APP_ADMIN_PASSWORD` sau lần khởi tạo đầu tiên không tự đổi mật khẩu admin trong database đang có.

#### Dừng hoặc chạy lại

```powershell
docker compose down
docker compose up -d
```

`docker compose down` giữ lại volume và dữ liệu. Chỉ dùng `docker compose down -v` khi chủ động muốn xóa toàn bộ database demo và dựng lại từ đầu.

Xem log khi khởi động lỗi:

```powershell
docker compose logs db-init api
```

Hướng dẫn Compose đầy đủ nằm tại [`docs/development/DOCKER_DEMO.md`](docs/development/DOCKER_DEMO.md).

### Cách 2 - Cài và chạy trực tiếp trên Windows

#### Yêu cầu

| Công cụ | Phiên bản/yêu cầu |
| --- | --- |
| Git | 2.40 trở lên |
| PowerShell | 7 trở lên |
| Node.js | 22 trở lên |
| JDK | 21 trở lên; `JAVA_HOME` trỏ tới JDK |
| SQL Server | 2022 Developer hoặc Express |
| SQL client | `sqlcmd`, SSMS hoặc Azure Data Studio |

SQL Server phải bật TCP/IP để Spring Boot kết nối qua JDBC. Nếu dùng cấu hình mặc định, kiểm tra cổng bằng:

```powershell
Test-NetConnection 127.0.0.1 -Port 1433
```

#### Bước 1: Kiểm tra môi trường

Từ thư mục gốc repository:

```powershell
pwsh -File scripts/setup.ps1
```

Script kiểm tra Git, PowerShell, Node.js, Java và cài dependency frontend nếu có.

#### Bước 2: Khởi tạo database và dữ liệu demo

Các lệnh sau dùng Windows Authentication và yêu cầu chưa có database `BlueStock`:

```powershell
sqlcmd -S localhost -E -C -b -i database/init.sql
sqlcmd -S localhost -E -C -b -d BlueStock -i database/seed/demo.sql
```

`database/init.sql` không xóa hoặc ghi đè database đã tồn tại. Nếu cần nâng cấp database cũ, làm theo [`database/README.md`](database/README.md) thay vì chạy lại `init.sql`.

#### Bước 3: Cấu hình kết nối backend

Tạo một SQL login cục bộ có quyền trên database `BlueStock`, sau đó đặt biến môi trường trong terminal sẽ chạy API:

```powershell
$env:SPRING_DATASOURCE_URL = 'jdbc:sqlserver://127.0.0.1:1433;databaseName=BlueStock;encrypt=true;trustServerCertificate=true'
$env:SPRING_DATASOURCE_USERNAME = '<sql-login>'
$env:SPRING_DATASOURCE_PASSWORD = '<local-password>'
```

Không ghi mật khẩu thật vào repository. File [`services/api/.env.example`](services/api/.env.example) chỉ là mẫu và Spring Boot không tự nạp file này.

Hướng dẫn tạo login kỹ thuật và bật TCP/IP nằm tại [`docs/development/BUILD_GUIDE.md`](docs/development/BUILD_GUIDE.md).

#### Bước 4: Tạo tài khoản admin lần đầu

Khi bảng tài khoản còn trống, chạy:

```powershell
pwsh -File scripts/bootstrap-admin.ps1
```

Nhập mật khẩu admin dài ít nhất 12 ký tự khi được hỏi. Script tạo tài khoản `admin`, khởi động API và lưu mật khẩu dưới dạng BCrypt hash. Sau khi tạo thành công, nhấn `Ctrl+C` để dừng tiến trình bootstrap.

#### Bước 5: Chạy backend và frontend

Terminal 1, giữ nguyên các biến môi trường JDBC ở bước 3:

```powershell
pwsh -File scripts/dev.ps1 -Target api
```

Terminal 2:

```powershell
pwsh -File scripts/dev.ps1 -Target web
```

Kiểm tra và sử dụng:

- API health: [http://127.0.0.1:8080/actuator/health](http://127.0.0.1:8080/actuator/health).
- Ứng dụng kết nối API: [http://127.0.0.1:5174/?mode=api](http://127.0.0.1:5174/?mode=api).
- Đăng nhập bằng `admin` và mật khẩu đã nhập ở bước bootstrap.

Nếu chỉ muốn xem prototype không cần database/API, chạy web rồi mở [http://127.0.0.1:5174/](http://127.0.0.1:5174/).

### Đổi cổng khi bị trùng

Ví dụ chạy API ở cổng `8082` và web ở cổng `5176`:

```powershell
# Terminal API
$env:SERVER_PORT = '8082'
$env:APP_WEB_ORIGIN = 'http://127.0.0.1:5176'
pwsh -File scripts/dev.ps1 -Target api

# Terminal web
pwsh -File scripts/dev.ps1 -Target web -Port 5176
```

Mở `http://127.0.0.1:5176/?mode=api&apiPort=8082`.

Khi dùng Docker, sửa `DB_PORT`, `API_PORT`, `WEB_PORT` trong `.env`; nếu đổi `API_PORT`, thêm `apiPort` vào URL frontend như ví dụ trên.

## Kiểm tra trước khi bàn giao

Chạy cổng kiểm tra mã nguồn từ root repository:

```powershell
pwsh -File scripts/verify.ps1
```

Khi SQL Server đã sẵn sàng, chạy thêm test database và concurrency:

```powershell
pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency
```

Nếu kiểm tra SQL Server của Compose, xem lệnh có `SqlServer` và `SqlUser` tại [`docs/development/DOCKER_DEMO.md`](docs/development/DOCKER_DEMO.md).

## Xử lý lỗi thường gặp

| Hiện tượng | Cách kiểm tra |
| --- | --- |
| Frontend chỉ hiện dữ liệu mẫu | URL phải có `?mode=api`; kiểm tra API đang chạy ở đúng cổng |
| API không kết nối được SQL Server | Kiểm tra TCP/IP, cổng 1433, JDBC URL và SQL login |
| CORS hoặc session không hoạt động | Dùng cùng host `127.0.0.1` và đặt `APP_WEB_ORIGIN` khớp chính xác URL web |
| `BlueStock` đã tồn tại | Không chạy lại `init.sql`; đọc hướng dẫn migration trong `database/README.md` |
| Docker API chưa lên | Chờ `db` healthy, kiểm tra mã thoát `db-init`, rồi xem `docker compose logs db-init api` |
| Port 8080/5174 đang bận | Đổi port theo mục **Đổi cổng khi bị trùng** |

## Cấu trúc repository

```text
apps/web/                 Frontend quản lý kho
services/api/             Spring Boot API theo module nghiệp vụ
database/                 Schema, migration, procedure, function, trigger, view, index, seed và test
contracts/                Hợp đồng API/DTO giữa frontend và backend
docs/                     Kiến trúc, yêu cầu, hướng dẫn, kiểm thử và quản trị dự án
scripts/                  Lệnh setup, chạy local, bootstrap và kiểm tra
references/               Project tham khảo, không phải nguồn yêu cầu nghiệp vụ
```

## Tài liệu chính

- [`AGENTS.md`](AGENTS.md): quy tắc làm việc trong repository.
- [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md): mục tiêu, hiện trạng và invariant của hệ thống.
- [`docs/development/BUILD_GUIDE.md`](docs/development/BUILD_GUIDE.md): hướng dẫn build local chi tiết.
- [`docs/development/DOCKER_DEMO.md`](docs/development/DOCKER_DEMO.md): hướng dẫn Docker Compose.
- [`apps/web/README.md`](apps/web/README.md): cách dùng frontend và các màn hình API.
- [`services/api/README.md`](services/api/README.md): cấu hình và endpoint backend.
- [`database/README.md`](database/README.md): schema, seed, migration và test SQL Server.
- [`docs/testing/API_SMOKE.md`](docs/testing/API_SMOKE.md): kịch bản demo nhập → tồn → xuất FEFO → báo cáo.

Thư mục `references/` chỉ dùng để tham khảo cách tổ chức; không phải nguồn sự thật của dự án BlueStock.
