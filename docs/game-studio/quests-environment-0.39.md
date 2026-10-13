# 0.39 — Người giữ trại và sáu nhiệm vụ đầu

## Phạm vi
PC local, tiếp nối 0.38. Tạo 4 NPC có vị trí/vai trò/lời thoại riêng, dùng rig nhân vật 0.37 và diện mạo có sẵn, hoạt ảnh idle/chớp mắt/quay mặt/cử chỉ trò chuyện. Bổ sung 6 nhiệm vụ có nhận–tiến độ–trả–phần thưởng thật và lưu trạng thái. Môi trường ba vùng thêm mốc sinh hoạt, vật trang trí theo vai trò, biển chỉ dẫn và chuyển động tiết chế. Không thay concept nhân vật.

## Nội dung / vòng chơi
- **Lâm An**, người giữ trại (Vạn Thú Sơn): giới thiệu và nhiệm vụ gặp dược sư, giữ lối về trại.
- **Yên Chi**, dược sư (Vạn Thú Sơn): giải thích nuôi Cổ, nhiệm vụ cho Cổ ăn.
- **Thẩm Nghi**, người giữ cổ trận (Tàn Tích): truyền thuyết Thanh Nang, nhiệm vụ phục hồi bí cảnh; trả cho Mộc Miên tại đích đến.
- **Mộc Miên**, người chăm linh điền (Thanh Nang): nhận lại dấu ấn, nhiệm vụ vụ mùa đầu, nuôi tằm/chăn nuôi và luyện Cổ.

Sáu nhiệm vụ: Lời dặn dưới đèn → Giữ lối về trại / Cổ cũng cần bữa ăn → Dấu ấn thất lạc → Gieo lại linh mạch → Tơ nuôi Cổ. Nhánh nuôi Cổ độc lập sau nhiệm vụ đầu, không chặn khám phá. Thành tựu đã thực hiện được tính khi nhận nhiệm vụ; không buộc người chơi làm lại nâng cấp đã hết mức. Nhận nhiệm vụ không tự nhận thưởng; trả đúng NPC, đúng phạm vi và đủ điều kiện mới cấp thưởng một lần. Túi đầy dùng hàng chờ hiện có.

## Trạng thái và ranh giới
QuestCatalog chứa content; QuestJournal sở hữu accepted/claimed/counters, validator/migration và các truy vấn mục tiêu. LocalAuthority nhận lệnh talk/accept/claim, kiểm tra sống/ngoài giao chiến/cùng vùng/gần NPC/line-of-sight, phát sự kiện bền vững và lưu cùng hồ sơ. Counter chỉ nhận từ sự kiện gameplay được chấp nhận. QuestJournal không phụ thuộc HUD. Hồ sơ cũ thiếu `quests` dùng mặc định; thành tựu feed/kill/realm/Gu lấy từ trạng thái gốc để tương thích.

DialoguePanel đọc truy vấn và phát lệnh, có lựa chọn lời thoại/hỏi nhiệm vụ/nhận/trả/tạm biệt; không sửa kho đồ. NPC View dùng cùng animation rig với nhân vật, đứng trên pivot cố định, y-sort với thế giới; không lắc nguyên sprite. UI hội thoại sở hữu input; ESC đóng, mở dừng đường đi; mất cự ly/vùng/chết đóng hội thoại. Giảm chuyển động vẫn giữ tên/dấu nhiệm vụ, dừng chuyển động trang trí.

Giữ khảo nghiệm nhập môn cũ trong nhật ký để bảo toàn tiến độ; thêm tab nhiệm vụ NPC trong F11 và theo dõi trong HUD khi đã nhận. Bấm NPC chỉ mở hội thoại khi gần; ở xa hướng dẫn lại gần, không gửi đòn đánh/di chuyển xuyên UI. E ưu tiên tương tác gần nhất, tránh NPC cướp phím của cổng/đất.

## Môi trường và phản hồi
Trại có góc dược liệu, cờ hướng dẫn và đồ sinh hoạt; Tàn Tích có bàn khảo cổ/biển cổ trận/hoa văn vỡ; bí cảnh có ao sen có bờ rõ, góc nông cụ và lối đất trồng. Vật thể cao có footprint va chạm, đường đến NPC/cổng/ô đất vẫn thông. Dùng nét vector/màu ngọc-giấy hiện có cho chi tiết mới; đồ nền hiện hành được giữ. Tránh bụi/đốm phủ lên mặt và silhouette nhân vật. Nhận nhiệm vụ có âm xác nhận, trả nhiệm vụ có thưởng/âm thanh; marker `!`/`?` có hình và nhãn, không chỉ dùng màu.

## WBS và nghiệm thu
1. Catalog/quest persistence/commands: nhận và trả đúng điều kiện, không nhận thưởng lặp, hồ sơ lỗi không gán một phần.
2. Dialogue + nhật ký/HUD/input: hội thoại lựa chọn, chỉ dẫn tiến độ/phần thưởng, dẫn đến người trả; cửa sổ không rò input.
3. NPC animation + môi trường: 4 NPC, marker, cử chỉ; ba vùng có mốc khác nhau, navigation đến các tương tác hợp lệ.
4. Kiểm chứng: cơ chế, migration, native keyboard/click/dialogue/quest; screenshot960/1280 và chuỗi frame NPC; hồi quy 0.38 và nhân vật.

Thực hiện builder → tự review → verifier trong task hiện tại. Chưa bao gồm lồng tiếng, cutscene dài, lịch sinh hoạt NPC/ngày đêm, hàng chục quest và thoại nhánh thay đổi cốt truyện lớn. Đây là vòng nhập môn chơi được; cần người chơi thử nhịp nhiệm vụ trước khi mở rộng nội dung.

## Kết quả thực hiện

Bốn hạng mục WBS đã triển khai và kiểm trong phạm vi PC local. `quest_catalog.json` tách nội dung khỏi UI. Nâng Cổ gửi metadata `cultivated_gu` rõ ràng; đổi trứng không cộng nhầm tiến độ nâng Cổ. Cùng một bộ chọn tương tác phục vụ phím E và gợi ý NPC. Thẩm Nghi đứng tại (9,20), tách khỏi cột đèn. Marker đang làm vẽ ba chấm bằng geometry, đặt trên nón để không bị artwork che.

- 70/70 kiểm cơ chế quest: [JSON](../../artifacts/quests39_mechanics.json).
- 60/60 kiểm điền viên/nâng Cổ: [JSON](../../artifacts/quests39_cultivation.json).
- 613/613 hồi quy: [JSON](../../artifacts/quests39_regression.json).
- 48/48 native: 13 ảnh màn hình + 24 frame cử chỉ, tại 1280×800/960×640; [JSON](../../artifacts/quests39_native.json).
- Trang review có chọn tab, phát/dừng và xem từng frame: [HTML](../../artifacts/quests39_review.html); kiểm Chrome tại 1360/960/390 px: [JSON](../../artifacts/quests39_browser.json).

Đã xem trực tiếp ảnh trại, hội thoại, nhật ký, Tàn Tích, bí cảnh, giao diện nhỏ và frame cử chỉ; sửa khung giấy, vị trí NPC/cột đèn và marker bị nón che. Native dùng input thật cho nhận/trả nhiệm vụ và UI; dùng fixture bỏ qua thời gian combat/unlock ở chặng sau, được bù bằng chuỗi authority trong tests cơ chế. Rig cử chỉ dùng lại idle/channel unarmed, chưa có clip nghề nghiệp hay lịch đi lại riêng. Map gốc vẫn dùng atlas hiện hành, chi tiết bổ sung vẽ vector. Đây không phải nghiệm thu toàn bộ mỹ thuật phát hành.

## Chạy lại

```bash
bash tools/run.sh --headless --script res://tests/quest_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/cultivation_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/quest_visual_smoke.gd -- --test-mode
python3 tools/build_quests39_review.py
```

Sau hồi quy, sao chép `artifacts/test_results_linux.json` thành `artifacts/quests39_regression.json`; sau điền viên, sao chép `expansion38_mechanics.json` thành `quests39_cultivation.json` để lưu evidence của lượt kiểm. Chạy các capture native tuần tự. `--test-mode` bắt buộc để cô lập save thật. Browser harness: `tools/verify_quests39_review.cjs`, dùng Chrome và server artifacts ở cổng 8879 như các bản review trước.

Rollback: các file cũ đã lưu tại `artifacts/quests39_baseline/`; file mới thuộc catalog/journal/dialogue/NPC/environment và hai harness `quest_*`. Không phục hồi toàn bộ thư mục dự án hoặc xóa hồ sơ người chơi. Trạng thái `quests` là trường tùy chọn trong profile schema 1, runtime cũ bỏ qua trường mới.
