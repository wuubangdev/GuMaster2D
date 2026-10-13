# 0.40 — Ba đại vực và tuyến truyền thừa

## Yêu cầu / phạm vi triển khai
Mở ba vùng hiện hành từ 28×28 lên 96×96 ô (3.072×3.072 đơn vị thế giới, diện tích gấp 11,76 lần/vùng). Giữ khu nhập môn và ID vùng/save cũ; mở thêm đường, sông/hồ có cầu, rừng/đầm/di tích, bãi quái, tài nguyên, điểm dịch chuyển nội vùng. Map có nội dung phân bố rõ, không chỉ kéo dài nền trống.

- Thanh Mao Sơn (ID forest): trại tông tộc, rừng trúc, bãi lợn, đầm nhện, mật lâm, khe sói, đỉnh lang vương. Sáu bãi farm; quái nhập môn cũ vẫn có mặt gần trại.
- Tam Vương Cổ Địa (ID ruins): trại khảo cổ, mỏ nguyên thạch, độc đàm, hành lang tàn trận, thạch điện, bãi phế tích và điện truyền thừa. Sáu bãi farm.
- Thanh Nang Phúc Địa (ID realm): giữ điền viên an toàn ở góc nhập môn; mở khu hoang phía ngoài có hoa, đầm, rừng linh thú và trận nhãn bị ô nhiễm. Bốn bãi farm, không có quái lọt vào ruộng.

Tám định nghĩa quái gồm sói, lợn rừng, nhện, ong, cóc, thạch giáp trùng và hai biến thể đầu lĩnh; khác silhouette, HP, tốc độ, sát thương, tầm, hành vi và loot. Cận chiến, lao theo hướng báo trước, phun vào vùng đã báo; được né bằng di chuyển, vật cản ngăn sát thương. Bãi có giới hạn truy đuổi/hồi sinh, quái xa không chạy tìm đường liên tục.

Giữ 6 quest hiện có và thêm 12 quest chính/phụ (18 tổng); 3 NPC mới (7 tổng). Mục tiêu gồm khám phá, hạ quái ở đúng bãi, giao vật liệu, đầu lĩnh. Thưởng bạc/XP/nguyên liệu và mở chức năng: trạm dịch chuyển nội vùng đã khám phá, dùng dược liệu hồi phục ngoài giao chiến, tưới toàn bộ luống đã gieo. Không khóa lại chức năng 0.39 của hồ sơ cũ.

## Cốt truyện và tham khảo
Cốt truyện riêng: trại khai thác linh tuyền để nuôi Cổ, lang triều xuất hiện do vết nứt linh mạch, dấu vết truyền thừa dẫn tới cổ địa, khôi phục phúc địa rồi giải quyết vùng hoang ảnh hưởng mùa vụ. NPC có lợi ích khác nhau (an toàn của trại, nguyên liệu, kiến thức, duy trì linh mạch); quest phụ bổ sung kinh tế và lựa chọn thứ tự đi bãi. Đây là diễn giải cho game, không tái hiện nguyên văn tuyến Phương Nguyên hay khẳng định địa danh tự viết thuộc nguyên tác.

Nguồn đã tra ngày 2026-10-12:
- [Bản giới thiệu chính thức trên WebNovel](https://www.webnovel.com/book/reverend-insanity_7996858406002505): thế giới nuôi, luyện và sử dụng Cổ; nền cho vòng kinh tế–chiến đấu.
- [Flower Wine Monk — wiki cộng đồng](https://reverend-insanity.fandom.com/wiki/Flower_Wine_Monk): mô-típ truyền thừa và dấu tích để lại.
- [Hu Immortal Blessed Land — wiki cộng đồng](https://reverend-insanity.fandom.com/wiki/Hu_Immortal_Blessed_Land): thảo mộc, sinh linh và tài nguyên luyện Cổ trong phúc địa.
- [Cultivation / Saga of Gu — tổng hợp cộng đồng](https://sagaofgu.com/cultivation/): tông tộc, nguồn lực và lang triều Thanh Mao. Dùng như tham khảo phụ, không phải văn bản nguyên tác.

## Kiến trúc và lưu
WorldContent/Bestiary là catalog dữ liệu; WorldGrid tạo địa hình/va chạm/đường. JourneyModel giữ khám phá, thu thập và thời gian hồi tài nguyên; QuestJournal giữ tiến độ từng bãi/điều kiện thưởng. Unlock chức năng suy ra từ quest đã trả, không lưu flag thứ hai có thể lệch. Authority xác thực lệnh trước tiêu hao; giao vật liệu và trả thưởng cùng một lệnh. UI bản đồ, danh sách bãi và nhật ký chỉ đọc trạng thái/phát ý định. Save field journey tùy chọn, hồ sơ 0.39 mặc định rỗng; vị trí cũ được giữ nếu còn đi được.

## WBS / nghiệm thu
1. Catalog bản đồ/quái/cốt truyện: ba map 96×96, 16 bãi, 8 loại, 18 quest/7 NPC; đồ thị quest không vòng, yêu cầu/công thức có nguồn tài nguyên.
2. World/navigation/runtime: cầu có đường qua sông, mọi bãi/NPC/điểm tương tác đi đến được; giảm xử lý actor ở xa; giữ vùng ruộng an toàn.
3. Combat/loot/tài nguyên: mỗi loài có hành vi và drop thật; telegraph khớp hit test, có thể né, không đánh xuyên vật cản/vùng an toàn; thu thập có cooldown và persistence.
4. Quest/unlock/UI: chính/phụ và vị trí rõ; dẫn đường tới mục tiêu; bản đồ vùng và trạm đã khám phá; thưởng chức năng thực thi trong authority.
5. Verification: kiểm mô phỏng/migration/đường đi/kinh tế, tương tác và ảnh native từng vùng/loài; hồi quy các contract không chủ ý đổi. Cập nhật tests số lượng quái và vùng hoang theo phạm vi mới, không hạ kiểm va chạm/transaction.

Builder → tự review → verifier trong task hiện tại. Không gồm online/MMO, lịch sự kiện máy chủ, world streaming vô hạn hay xác nhận cân bằng phát hành. Map/quest thực thi được là mục tiêu; kiểm hiệu năng có báo cáo riêng theo môi trường chạy, không suy rộng từ máy render phần mềm.


## Cách chơi và nội dung đã nối

- Bắt đầu ở Lâm An, hoàn thành **Lời dặn dưới đèn**, nhận **Đường qua rừng trúc**. T → Trong vùng → chọn Rừng trúc đông → Dẫn đường. Trở về trả quest để mở dịch chuyển nội vùng; ghé từng trạm ghi dấu trước khi dùng (5 bạc/lượt).
- Giữ lối về trại và khám phá rừng trúc → Trác Sơn giao **Dấu chân trong lang triều** → hạ Điện lang ở đông nam → Thẩm Nghi giao **Tàn quyển dưới thạch giáp** và **Giá của truyền thừa** → Linh Nha dẫn vào **Linh mạch dưới rừng hoa**, **Khơi lại dòng Thanh Nang**. Tuyến nhập môn phục hồi cổng/ruộng cũ vẫn hoạt động song song.
- Quest phụ thu da, mật, khoáng, độc nang và phấn; đồ giao sẽ bị trừ khi trả quest. **Dược phương đường xa** mở R: ngoài giao chiến, dùng 2 linh thảo + 1 mật, hồi tối đa 40% HP, hồi chiêu 15 giây. **Khơi lại dòng Thanh Nang** mở H → Tưới toàn bộ linh điền, không bỏ qua thời gian lớn của cây.
- E thu thập 32 nguồn ngoài đồng (2 vật liệu/lượt, 75 giây chơi để hồi). F11 lọc chính/phụ, theo dõi hoặc tìm mục tiêu. T có hai mục: địa đồ hiện tại và sang vùng khác. Radar theo khu vực đang đứng; chấm trắng là người chơi.
- Quần thể thực tế: 37 ở Thanh Mao Sơn, 37 ở Tam Vương, 19 ở Thanh Nang; tổng 93, gồm 12 sói nhập môn cũ. Quái thường hồi 28–45 giây, Điện lang 120 giây, thủ vệ 150 giây. Có ba cá thể đầu lĩnh thuộc hai định nghĩa loài (thủ vệ xuất hiện cả cổ địa và trận nhãn phúc địa).

## Lưu, hồi quy và giới hạn

Backup nguồn trước thay đổi ở `artifacts/world40_baseline/`. Không phục hồi nguyên file từ backup nếu đã có thay đổi sau 0.40; đối chiếu từng phần. Game PC đơn, chưa triển khai mạng. Save schema 1 giữ quest/inventory/appearance; field journey mới có validator riêng. Không đọc/ghi hồ sơ thật trong test. Các PNG concept/rig của người chơi không sửa.

Diện tích rộng hơn không đồng nghĩa bản đồ vô hạn: mỗi vùng 96×96 ô, đặt nội dung cố định và có va chạm. Quái đang ở vùng không hoạt động giữ nguyên timer khi sang vùng khác; load game tạo lại quần thể, như cơ chế trước. Nguồn thu thập và dược phương lưu timer; cây/thú/tài nguyên chỉ chạy theo thời gian chơi, không tính offline. Các lệnh debug fixture chỉ có trong tests. Loot/rank/HP hiện là thông số khởi đầu, cần playtest cân bằng dài hạn; nanh điện lang hiện là chiến lợi phẩm sưu tầm. Không xác nhận hoàn thiện mỹ thuật phát hành hoặc hiệu năng Windows/Web/mobile.

Chạy lại:
```sh
bash tools/run.sh --headless --script res://tests/world_expansion_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/quest_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/cultivation_tests.gd -- --test-mode
bash tools/run.sh --headless --script res://tests/test_runner.gd -- --test-mode
DISPLAY=:0 bash tools/run.sh --audio-driver Dummy --script res://tests/world40_visual_smoke.gd -- --test-mode --capture-offscreen
```
`tools/author_world40_data.py` tái tạo dữ liệu định nghĩa, đã kiểm tính lặp lại không đổi nội dung. `tools/build_world40_review.py` ghép ảnh framebuffer nguyên bản với danh mục quest; không dựng lại hình bằng HTML. Trình xem cần server thư mục artifacts tại cổng 8879; test browser ở `tools/verify_world40_review.cjs`.


## Kết quả nghiệm thu 2026-10-12
WBS 1–5 đã triển khai và kiểm trong bản PC local: **1211/1211** lượt kiểm, 0 failure; 413 world, 76 quest, 60 cultivation, 49 native, 613 regression. Hai PNG concept giữ nguyên hash. [Bảng bằng chứng](quality-report.md), [delivery JSON](../../artifacts/world40_delivery.json), [23 ảnh native và danh mục 18 quest](http://localhost:8879/world40_review.html). Art và cân bằng phát hành tiếp tục là phần chưa nghiệm thu.
