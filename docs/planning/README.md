# GuMaster2D — Bộ tài liệu lập kế hoạch

Ngày:07/10/2026. Đội 4 người tự phát triển, chưa có ngân sách; Godot PC native trước; Web spike.

- `GuMaster2D_Project_Plan.docx`: bản Word để đọc và trao đổi.
- `GuMaster2D_FSD_WBS_Plan.xlsx`:25 sheet chi tiết, có công thức và lịch.
- `GuMaster2D_Project_Plan.md`: bản Markdown của Word.
- `GuMaster2D_FSD.md`: toàn bộ 55 yêu cầu chức năng và12 NFR.
- `GuMaster2D_WBS.md`:72 work packages, dependencies, effort và DoD.
- `validation_report.json`: kết quả kiểm tra tính nhất quán tài liệu; không phải test game.

Giả định:20h/người/tuần;75% hữu ích;20% dự phòng;36 tuần. Ngày 12/10/2026–18/06/2027 chỉ minh họa.
Trong Excel, sửa 00_START!B7/B8/B9/B10 rồi xem19_RESOURCE và 20_SPRINT_LOAD. Đổi availability không tự nén WBS/Gantt; cần rebaseline.

## Tạo lại tài liệu

Source: tools/planning_data.py và tools/plan_template.md. Generator: tools/generate_plan.py.
Kế hoạch code Godot và trạng thái prototype: ../implementation/GODOT_IMPLEMENTATION_PLAN.md. Cần Python 3.12+ với openpyxl và python-docx. Generator không sửa file DAUN gốc.
Chạy: `python tools/generate_plan.py` từ thư mục này.

Chạy generator sẽ ghi đè các artifact đã tạo. Nếu đã chỉnh Excel/Word thủ công, hãy lưu bản copy và đưa thay đổi về source trước chạy lại.
Mọi testcase game ở trạng thái Chưa chạy; các NFR chưa được benchmark. Cash sheet đơn giá 0 là input chờ điền, không phải cam kết miễn phí hosting.
