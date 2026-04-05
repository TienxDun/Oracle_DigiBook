# 👨‍🏫 Bí Kíp Sinh Tồn Vấn Đáp SQL (Oracle 19c) - DigiBook

Chào các "kỹ sư tương lai"! Thầy biết lúc này các em đang nhìn đống SQL hàng ngàn dòng và tự hỏi: "Mình là ai? Đây là đâu? Mớ code này sinh ra để làm gì?". Đừng hoảng! Tài liệu này không khô khan như sách giáo khoa đâu. Thầy sẽ phân tích hệ thống DigiBook bằng ngôn ngữ "loài người" nhất có thể để các em hiểu sâu, nhớ lâu và tự tin chốt hạ môn Cơ sở dữ liệu nhé! 😎

Đặc biệt lưu ý: **File 4 (Procedures)** và **File 5 (Triggers)** là 2 "mỏ vàng" câu hỏi xoáy của Hội đồng. Thầy sẽ phân tích thật kỹ phần này.

---

## 🗺️ Bản Đồ Toàn Cảnh (Nhìn 1 phút là nhớ)

Tưởng tượng chúng ta xây một ngôi nhà (Hệ thống DigiBook), các em phải nắm rõ **trình tự chạy đúng** từ File 2 đến 9:
1. **File 2**: Xây móng, đổ cột (Tạo Bảng, Khoá chính, Ràng buộc, Sequence).
2. **File 3**: Mua đồ nội thất bỏ vào nhà (Nạp dữ liệu mẫu - Insert Data).
3. **File 4**: Dạy Robo-Quản-Gia làm việc (Procedures - Nghiệp vụ phức tạp).
4. **File 5**: Lắp hệ thống báo động & tự động hoá (Triggers - Validate, Auto-sync, Audit Log).
5. **File 6**: Lắp camera an ninh & màn hình theo dõi (Views, Materialized Views - Đọc nhanh, che giấu dữ liệu).
6. **File 7**: Phân loại đồ đạc để tìm cho lẹ (Indexes - Tối ưu truy vấn).
7. **File 8**: Phát chìa khoá cho thành viên (Security/Roles - Phân quyền Admin, Staff, Guest).
8. **File 9**: Demo giao dịch thực tế - Mua hàng trừ kho (Transaction - ACID, Lock, Exception Handling).

---

## 🕵️‍♂️ Đi Sâu Vào Từng "Căn Phòng" (Từng File)

### 🧱 File 2 - "Xây Móng & Đổ Cột" (Tạo Bảng)
**Cái gì?**
Tạo 25 bảng chia làm 6 module (Hệ thống, Catalog, Bán hàng, Kho, Thanh toán, Review). Có xài `Sequence` để tự tăng ID qua Trigger `BEFORE INSERT`.

**Tại sao?**
- Hệ thống đa chi nhánh cần `branches` làm trung tâm. `orders` hay `inventory` đều phải chĩa `FOREIGN KEY` (FK) về đây.
- Có sự xuất hiện của cột `stock_quantity` trong bảng `books` trong khi đã có bảng `branch_inventory` chứa số lượng. Tại sao? 👉 Đó là **Denormalization** (phi chuẩn hóa) để khi load trang web, query chạy chớp mắt lấy ra số lượng tồn thay vì phải SUM hàng chục ngàn bản ghi dưới kho hàng.

**Hỏi xoáy đáp xoay (60s vàng):**
- **Hỏi:** Tại sao không dùng Identity (Auto-increment) mà dùng Sequence + Trigger?
- **Đáp:** Dạ thưa thầy/cô, Sequence tồn tại độc lập với bảng. Nó linh hoạt hơn khi em muốn chủ động lấy `NEXTVAL` cho logic lập trình trước khi thực sự Insert, và dễ kiểm soát gán ID trên Oracle 19c ạ!

---

### 🛋️ File 3 - "Chuyển Đồ Vào Nhà" (Nạp Dữ liệu)
**Cái gì?** 
Chèn ~250 bản ghi. Trình tự lùi tiến: **xoá con trước, xoá cha sau**, rồi mới **chèn cha trước, chèn con sau**.

**Tại sao?**
Dữ liệu mẫu không phải ngẫu nhiên mà được thiết kế có ý đồ: Đơn hàng thành công, đơn bị huỷ, kho thiếu hàng đợi điều chuyển... Đây là "vật tế thần" để tí nữa test mấy câu code phức tạp ở File 4 và 5.

**Hỏi xoáy đáp xoay (60s vàng):**
- **Hỏi:** Trong script em có lệnh `DELETE` ở đầu File 3, tại sao phải xoá `wishlists` rồi mới xoá `customers`?
- **Đáp:** Ràng buộc khoá ngoại ạ! Giả sử xoá dữ liệu khách hàng trước thì danh sách yêu thích của khách hàng đó trở thành "kẻ mồ côi", Oracle sẽ báo vi phạm toàn vẹn dữ liệu ngay.

---

### 🤖 File 4 - "Dạy Robo-Quản-Gia" (Procedures) - 🔴 TRỌNG TÂM
**Slogan:** Nghiệp vụ nằm chặt ở Database thì 10 ứng dụng ăn theo (Web, iOS, Android) cũng không bao giờ lệch số liệu.

**Cái gì? (Facts)**
Bọn em tạo 4 Stored Procedure quan trọng:
1. `sp_manage_book`: Thực hiện ADD/UPDATE/DELETE sách (gom 1 cửa).
2. `sp_report_monthly_sales`: Trả về con trỏ `SYS_REFCURSOR` cho báo cáo doanh thu.
3. `sp_print_low_stock_inventory`: `CURSOR` duyệt danh sách cảnh báo hết hàng.
4. `sp_calculate_coupon_discount`: Tính tiền mã giảm giá Voucher.

**Tại sao? (Logic Dành Lấy Điểm Cao)**
- **Kỹ thuật "Gom nhóm biến động" (`sp_manage_book`):** Nhét cả 3 thao tác dữ liệu vào 1 SP, dùng biến `p_action`. Đoạn xử lý DELETE rất hay: không cho DELETE bừa! Nó phải kiểm tra sách đã có đơn hàng (`order_details`) chưa. Có rồi thì nhảy vào khối `EXCEPTION` ném mã lỗi chủ động `RAISE_APPLICATION_ERROR`.
- **Tại sao trả về con trỏ (`sp_report_monthly_sales`)?** Oracle không dễ "RETURN Table" nhàn hạ như MySQL. Ta phải dùng `SYS_REFCURSOR` mở 1 cửa sổ, đẩy cửa sổ đó về cho C#/NodeJS ngoài Backend. Backend dùng vòng lặp cuộn từ từ (Fetch) lấy số liệu lên -> Không bao giờ gây tràn RAM (OOM) khi báo cáo hàng triệu dòng.
- **Tính toán Mã giảm giá Voucher (`sp_calculate_coupon_discount`):** Code phải chặn đầu đủ mọi bề: Quá hạn chưa? Vượt quá lượt dùng giới hạn (`usage_limit`) chưa? Mức giảm có lớn hơn mức trần (`max_discount_amount`) không?. Thầy ứng dụng hàm cực xịn là `LEAST(giá_trị_giam_giá, tổng_bill)` để không bao giờ có chuyện khách áp mã xong thì giá trị bill bị ÂM.

**Hỏi xoáy đáp xoay (60s vàng):**
- **Hỏi (xoáy):** Trong thực tế, tại sao hàm tính tiền Voucher (`sp_calculate_coupon_discount`) em lại nhét vô CSDL làm Procedure, sao không code bằng Backend (Java/NodeJS) cho thân thiện?
- **Đáp (chói lóa):** Thưa Hội đồng, đặt logic Voucher ở CSDL giống như đặt một "chốt chặn nguồn" (Single Source of Truth). Nếu công ty em có team làm Web (NodeJS), team làm App C# và team Kế Toán làm công cụ nội bộ; nếu nhét logic vô Backend thì 3 team phải code 3 lần, dễ xảy ra lọt rào (team A giảm lỗi 50% thay vì 5%). Để ở CSDL, ứng dụng nào cứ gọi SP là ra số trùng khớp 100%.

---

### 🚨 File 5 - "Hệ Thống Báo Động & Tự Động" (Triggers) - 🔴 TRỌNG TÂM
**Slogan:** Trigger là con dao hai lưỡi. Xài hay thì rảnh tay, xài dở thì "Mutating Table" nát gáo!

**Cái gì? (Facts)**
Có 3 Trigger cực khét được rải xuống:
1. `trg_biu_orders_validation`: "Bác bảo vệ" gác cửa ngăn dữ liệu ảo cho bang Orders.
2. `trg_aiud_branch_inventory_sync_book_stock`: "Kế toán" dùng `COMPOUND TRIGGER` đi cộng số lượng tồn.
3. `trg_aiud_orders_audit`: "Thư ký" lấy sổ bìa đen ghi vết `AUDIT LOG`.

**Tại sao? (Logic Dành Lấy Điểm Cao)**
- **Kiểm soát tính hợp lệ (Trigger 1):** Nó chặn người dùng (hay devBackend non tay) vô ý set giá tiền `< 0`. Nó ràng buộc cứng: Trạng thái `"CANCELLED"` thì mốc thời gian `cancelled_at` không thể dính giá trị NULL. Tự động chèn `SYSDATE` (ngày giờ hiện hành) vào nếu trống. Kín kẽ tuyệt đối!
- **Cứu Tinh Kỹ Thuật (Trigger 2 - Compound Trigger):** 
    - Bài toán: Khi nhập xuất kho cuốn "Harry Potter", em phải UPDATE tổng số lượng tồn của "Harry Potter" văng lên lại bảng sách (`books`).
    - Nỗi đau: Trong Oracle, nếu một Trigger dòng (For Each Row) CỐ TÌNH gọi hàm Select hay Update lại dữ liệu bảng mà nó ĐANG MẮC KẸT xử lý, Oracle sẽ tát một lỗi ORA-04091: MUTATING TABLE (Bảng đang biến đổi).
    - Lời giải: Sử dụng **Compound Trigger**. Nó chia làm 4 giai đoạn. Ở giai đoạn (After Row), ta "bỏ túi" ID sách vừa bị thay đổi vào một cái mảng tạm. Đợi chạy tới tút cuối cùng là giai đoạn chốt sổ (After Statement), mình mới lấy mảng ID đó lôi ra làm phép SUM() và UPDATE lại bảng Books. Dữ liệu mượt mà, không gặp lỗi khóa bảng!
- **Ghi Vet (Trigger 3):** Không ai thao tác ngầm được. Trigger Audit tự lấy `SYS_CONTEXT` chộp địa chỉ IP máy khách, tên môi trường phần mềm và ghi lại luôn `Old_Amount`, `New_Amount`. Hệ thống tài chính cực kỳ cần cái này!

**Hỏi xoáy đáp xoay (60s vàng):**
- **Hỏi (xoáy):** Có bạn rơi vào tình thế bị vặn: "Vậy bây giờ tôi nhét hết mọi tính toán của tôi vào Trigger thay cho Procedure được khỏi?"
- **Đáp (chói lóa):** Dạ KHÔNG ạ. Trigger thiết kế là thứ chạy "ngầm" vô hình. Nếu mình nhét Logic tính tiền, chiết khấu vào Trigger thì Code sẽ rất khó quản lý, xảy ra lỗi (bug) khó tìm nguyên nhân. Trigger chỉ phù hợp giới hạn trong nhiệm vụ: Đảm bảo Data Integrity (Validation, Default Value), Cập nhật đồng bộ các cột Denormalize (Như cái số tồn kho), và Viết Log (Audit). Các Business Logic chính phải đặt ở ngoài.

---

### 👁️ File 6 - "Camera An Ninh" (Views)
**Cái gì?** 
Tạo `vw_order_sales_report` phục vụ báo cáo. Tạo `vw_customer_secure_profile` để che giấu dữ liệu (Data Masking). Tạo tính doanh thu bằng `MATERIALIZED VIEW`.
**Tại sao?**
- Báo cáo mà mỗi lần vô Backend đều viết lệnh JOIN chằng chịt 6-7 cái bảng là ác mộng. Rút về 1 View chạy cho tiện.
- **View Masking** rất tinh tế. Khách tên "Nguyễn Văn A" - Email "nguyen@gmail.com" sẽ bị view cắt bằng `SUBSTR` hiển thị: `"ng***@gmail.com"`. Ngay đuôi View đánh cái chữ `WITH READ ONLY` khóa sổ, khỏi ai nảy sinh ý tà Update Data vào.
- **Materialized View (MV)** `mv_daily_branch_sales`: Khác biệt hoàn toàn view thường. Nó tạo ra 1 bảng vật lý thực sự. Tốc độ đọc lên Dashboard là "bay", chấp hàng triệu dòng hóa đơn, vì nó đã tính trước ra rồi.

---

### 🗂️ File 7 - "Phân Loại Đồ Đạc" (Indexes)
**Cái gì?** 
Tạo 4 index. Cái làm thầy chú ý nhất là `BITMAP INDEX` trên cột Thể loại Sách và một Function-based Index.

**Hỏi xoáy đáp xoay:**
- **Hỏi:** Thích thì em đánh Index `B-Tree` cơ bản cho cột thể loại (`category_id`) cũng được mà, sinh ra Bitmap Index làm màu chi?
- **Đáp:** Dạ vài chục ngàn cuốn sách DigiBook mà chỉ chia đâu tầm 10 thư mục (thể loại). Số lượng giá trị khác biệt thấp gọi là **Low Cardinality**. Với Low Cardinality, Oracle dùng Bitmap ánh xạ ma trận số 0 và 1 cực kỳ nhẹ, đỡ tốn RAM. Hơn nữa Bitmap phù hợp xử lý OLAP (Tra cứu báo cáo có nhiều điểu kiện AND, OR) hơn là B-Tree!

---

### 👮 File 8 - "Phát Chìa Khóa" (Security Roles)
**Cái gì?** Khai báo Role (ADMIN, STAFF, GUEST). Áp dụng chiêu bài "Đặc quyền tối thiểu" (Principle of Least Privilege).
**Tại sao?**
- Khách vãng lai (`GUEST_ROLE`) chỉ có tài cán xem sách (Select View Books).
- Nhân viên (`STAFF_ROLE`) cho quyền duyệt đơn hàng.
- Khi cấp quyền, em thấy dòng `GRANT EXECUTE ON SP_XX`! 👉 Bảng có quyền Select thì chưa đủ, Procecure (Hàm) thì phải cấp quyền `EXECUTE` thì người dùng mới có thể triệu hồi hàm đó.
- Code đầu File 8 có đoạn logic nhỏ: Kiểm tra nếu em đang đăng nhập là tước vị Root `CDB$ROOT`, máy sẽ chủ động ngắt và lôi em vào cấp nhỏ hơn là `PDB` thì mới cho phép tạo User. Rất hiểu biết về tính năng Đa Trọ (Multi-tenant) của bản Oracle 19c.

---

### ⚡ File 9 - "Giao Dịch Thực Tế" (PL/SQL Transaction Demo) - 🔴 TRỌNG TÂM
**Slogan:** ACID là 4 chữ cái vàng trong dữ liệu. File 9 là bằng chứp xác thực.

**Cái gì? (Facts)**
Một khối PL/SQL hoàn chỉnh (dùng `DECLARE...BEGIN...EXCEPTION...END`) diễn tả kịch bản: **Khách hàng mua 2 cuốn sách, kho tồn bị trừ đi, đơn hàng được tạo với ghi nhận chi tiết, trạng thái, lịch sử thay đổi - TẤT CẢ phải thành công nhất nhất, nếu có bất cứ sự cố nào cũng ROLLBACK ngay lập tức.**

Mục độ của khối này:
1. Tìm khách, tìm nhân viên bán hàng, tìm sách có tồn kho.
2. Sử dụng `FOR UPDATE WAIT 5` để "khóa" dòng sách đang thao tác trong 5 giây, tránh race condition (2 khách cùng mua 1 cuốn hết kho).
3. Tạo Order mới, chi tiết sách, cập nhật tiền, trừ tồn kho, ghi lịch sử giao dịch, viết audit log - 6 bước một lần đều đủ.
4. Nếu lỗi ANY xuất hiện, quay về trạng thái ban đầu (`ROLLBACK`).

**Tại sao? (Logic Dành Lấy Điểm Cao)**
- **Lock (`FOR UPDATE WAIT 5`)**: Nếu không khóa, 2 khách cùng lúc mua → dữ liệu hỗn loạn. Oracle khóa trên dòng (row-level lock) thay vì toàn bảng để tối ưu hiệu năng. `WAIT 5` nghĩa là: "Em nắm khóa này, nếu xảy ra tranh chấp (session khác cũng muốn), em chịu đợi 5 giây. Hết 5 giây thì xin phép kiếp khác (Exception ORA-00054)."
- **Isolation Level (`SET TRANSACTION ISOLATION LEVEL SERIALIZABLE`)**: Mục tiêu cao nhất - mọi Transaction chạy tách biệt như nó chạy riêng lẻ chứ không "xen" vào nhau. (Ngoài có 3 mức khác là READ UNCOMMITTED, READ COMMITTED, REPEATABLE READ, nhưng SERIALIZABLE là an toàn tuyệt đối).
- **Exception Handling Văn Minh**: Code không "ăn hành động sai lầm" im lặng. Nó bắt từng trường hợp cụ thể:
  - `NO_DATA_FOUND`: Không tìm khách hay sách → Báo "Dữ liệu đầu vào không đúng"
  - `e_insufficient_stock`: Sách hết → Báo "Tồn kho không đủ"
  - `e_resource_busy` (ORA-00054): Session khác giữ khóa → Báo "Bản ghi đang bị khóa bởi session khác"
  - `OTHERS`: Lỗi còn lại → Báo mã lỗi thực sự (`SQLERRM`).
- **Đảm Bảo ACID**: 
  - **A (Atomicity - Nguyên tử hóa)**: Hoặc làm toàn bộ 6 bước, hoặc 1 bước cũng không làm.
  - **C (Consistency - Nhất quán)**: Tiền, tồn, số lượng order_details luôn cân bằng.
  - **I (Isolation - Cô lập)**: SERIALIZABLE.
  - **D (Durability - Bền vững)**: `COMMIT` viết xuống đĩa cứng Oracle rồi thì lửa cũng không cháy mất!

**Hỏi xoáy đáp xoay (60s vàng):**
- **Hỏi (xoáy):** Sao lại dùng `FOR UPDATE WAIT 5` thay cho `NOWAIT` hoặc không khóa gì cả?
- **Đáp (chói lóa):** Dạ thưa thầy. Nếu không khóa (`WHERE ... AND ROWNUM = 1` bình thường), 2 khách mua đồng lúc, 2 câu SELECT chạy ra cùng 1 sách (vì nó vừa được mốt khách add vô), Update kho 2 lần = chỉ trừ 2 thay vì 1. Nếu dùng `NOWAIT` (kiểu "khóc dí"), 1 khách khóc được rồi, khách 2 vô tức khì bi lỗi, không đợi. Dùng `WAIT 5` giống như bảo: "Anh nắm trước, em chịu đợi 5 giây cho bạn chốt xong, dễ chịu hơn" 😄

- **Hỏi (xoáy):** Vậy loạn đạn là `ROLLBACK` khi lỗi - nó xóa hết dữ liệu hay chỉ xóa ở transaction hiện tại thôi?
- **Đáp (chói lóa):** ROLLBACK chỉ quay lại snapshot của Transaction hiện tại (Session của khách A mua hàng). Khách B (session khác) đã commit xong tính tiền lên thì khách A rollback không liên quan gì cả. Rollback an toàn 100%, nó không đụng đến session khác.

- **Hỏi (xoáy):** File 9 tạo ra 1 cái Order demo như vậy. Cái Order demo này có xin phép (Clear) dữ liệu trước hay là cứ loạn thêm vô Database?
- **Đáp (chói lóa):** Em có thể chạy File 3 trước (Clear xong rồi data lại), hoặc cuối File 9 thêm dòng `ROLLBACK;` để chạy demo xong rồi quay lại. Hoặc em tạo một Script riêng để `DELETE FROM orders WHERE order_code LIKE 'DEMO_%'` để mọi khách hàng/ sách/ tồn kho vẫn còn nguyên nhưng hóa đơn demo bị xoá sạch. Cách nào cũng được!

---

## 🚀 Bí Quyết Trả Lời Vấn Đáp Rút Gọn (Summary)

**Cấu trúc 1 câu trả lời hoành tráng (Dùng cho mọi câu hỏi hệ thống):**
`1. File đó làm gì` + `2. Xử lý khó khăn kỹ thuật nào` + `3. Giá trị thực tiễn cho dự án`

***Ví dụ mẫu: "Tính năng của Trigger 2 trong File 5 là gì?"***
👉 *"Dạ thưa thầy, Trigger này lo việc Update thông số Tồn Kho hiển thị mỗi khi kho hàng có hoạt động xuất nhập. (Vai trò) Khó khăn đối mặt là khi Update vào bảng đang thao tác sẽ nảy sinh Mutating Table làm hệ thống chết cứng. Em đã dùng Compound Trigger để tách quá trình ghi nhận ID và cập nhật ra hai đoạn thời gian khác nhau để giải quyết. (Kỹ thuật) Nhờ vậy, người dùng trên Web trải nghiệm tốc độ đọc hàng tồn kho nhanh gấp trăm lần mà Database vẫn nhất quán! (Thực tiễn)"*

Chúc các "kỹ sư" có một kỳ bảo vệ xuất sắc, trả lời như những người làm sản phẩm thực sự! Nhớ cười tự tin nhé! 💪🎯