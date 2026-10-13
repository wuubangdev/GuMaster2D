# Review nhân vật cũ — 0.16

Phạm vi theo yêu cầu đã làm rõ: tinh chỉnh nhân vật cũ thay vì tạo mẫu nhân vật khác. Đã khôi phục generator/rig0.15 rồi nâng phần màu/chất liệu trên chính131 lớp SVG đó; giữ đầu/mắt/tóc/trang phục, proportions, các hướng và tư thế animation.

Guard cho phạm vi: ghi131 hash alpha/kích thước/RGBA từ thư viện0.15 import thật trước khi sửa. Acceptance so alpha/kích thước để phát hiện đổi silhouette và so màu để phát hiện asset không thực sự thay đổi. Nét gấp vải bổ sung nằm trong phần áo cũ. Ảnh/clip native cuối dùng để review kết quả, test màu không chứng minh mức độ đẹp.

Giới hạn: dáng chibi cũ được giữ theo yêu cầu; đầu/thân có tám hình hướng, các khớp pha trộn liên tục. Nền/sói dùng atlas pixel cũ, có material chỉnh màu. QA cuối và source sạch nằm trong quality-report.md/verification_manifest.json. Không tuyên bố đạt chất lượng bản phát hành của game Steam.
