# flutter_string
Công cụ genarate language file cho flutter
- Đầu vào: File excel (.xlsx)
- Đầu ra: File json chứa các cột được quy định trong file config

## Điều kiện cần:
- Phải cài đặt Microsoft Office
- Cài đặt sẵn Dart SDK hoặc Flutter SDK và đặt dart vào biến môi trường

## Cách sử dụng:
#### 1. Chỉnh sửa file config 
- output_type: Kiểu dữ liệu cho file kết quả
- format: định dạng sẽ được in ra ở file kết quả. Ví dụ "#A": "#C" thì chúng ta sẽ lấy data từ cột A và cột C của file excel
- start_row: dòng bắt đầu lấy dữ liệu

#### 2. Chỉnh sửa file run.bat (Optional)
#### 3. Run file run.bat
