using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    public partial class UpdateVietnameseTreatments : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                -- 1. Cập nhật thông tin bệnh sang Tiếng Việt (Giữ nguyên illness_name tiếng Anh cho AI mapping)
                UPDATE [tree_illnesses] SET
                    [description] = N'Bệnh bạc lá vi khuẩn gây ra các vết sọc úng nước dọc theo gân lá; làm giảm khả năng quang hợp và năng suất.',
                    [symptoms] = N'Sọc úng nước dọc gân lá, quầng vàng, có dịch vi khuẩn; vết bệnh cũ chuyển màu nâu sẫm và khô.',
                    [causes] = N'Vi khuẩn Xanthomonas oryzae pv. oryzae; lây qua mưa, gió, nông cụ và hạt giống.',
                    [severity] = N'Cao'
                WHERE [illness_name] = N'Bacterial Leaf Blight';

                UPDATE[tree_illnesses] SET
                    [description] = N'Bệnh đốm nâu tạo ra các vết đốm bầu dục; thường gặp khi lúa bị stress dinh dưỡng.',
                    [symptoms] = N'Đốm nâu tròn hoặc bầu dục có viền sẫm màu trên lá; có thể lan rộng.',
                    [causes] = N'Nấm Bipolaris oryzae; phát triển mạnh khi độ ẩm cao, thiếu kali, gieo sạ dày.',
                    [severity] = N'Trung bình'
                WHERE [illness_name] = N'Brown Spot';

                UPDATE [tree_illnesses] SET
                    [description] = N'Mô lá khỏe mạnh, không phát hiện bệnh. Tiếp tục chăm sóc tốt.',
                    [symptoms] = N'Lá xanh đều, không có vết bệnh.',
                    [causes] = N'Không có.',
                    [severity] = N'Không'
                WHERE[illness_name] = N'Healthy Rice Leaf';

                UPDATE [tree_illnesses] SET
                    [description] = N'Đạo ôn gây vết đốm hình thoi (mắt én), tấn công lá, đốt và cổ bông; nguy cơ mất mùa cao.',
                    [symptoms] = N'Vết đốm hình thoi có viền nâu và tâm xám trắng.',
                    [causes] = N'Nấm Magnaporthe oryzae; lây qua bào tử gió; nặng hơn khi thừa đạm và sương mù nhiều.',
                    [severity] = N'Cao'
                WHERE [illness_name] = N'Leaf Blast';

                -- 2. Xóa các treatment cũ bằng tiếng Anh
                DELETE FROM [treatment_solutions];

                -- 3. Thêm các giai đoạn phát triển (Tree Stages) bằng tiếng Việt
                IF NOT EXISTS (SELECT 1 FROM [tree_stages] WHERE [stage_name] = N'Nảy mầm')
                BEGIN
                    INSERT INTO [tree_stages] ([stage_name], [description], [created_at])
                    VALUES 
                    (N'Nảy mầm', N'Hạt lúa bắt đầu nảy mầm sau khi gieo', GETDATE()),
                    (N'Mạ', N'Giai đoạn cây con phát triển ban đầu', GETDATE()),
                    (N'Đẻ nhánh', N'Cây bắt đầu phát triển nhiều nhánh', GETDATE()),
                    (N'Làm đòng', N'Chuẩn bị hình thành bông lúa', GETDATE()),
                    (N'Trổ bông', N'Lúa bắt đầu trổ bông', GETDATE()),
                    (N'Chín', N'Hạt lúa chín và sẵn sàng thu hoạch', GETDATE());
                END;

                -- Lấy các ID động để tránh lỗi khóa phụ
                DECLARE @StageDeNhanh INT = (SELECT TOP 1 [stage_id] FROM [tree_stages] WHERE [stage_name] = N'Đẻ nhánh');
                DECLARE @IllnessBlight INT = (SELECT TOP 1 [illness_id] FROM [tree_illnesses] WHERE [illness_name] = N'Bacterial Leaf Blight');
                DECLARE @IllnessBrownSpot INT = (SELECT TOP 1[illness_id] FROM [tree_illnesses] WHERE [illness_name] = N'Brown Spot');
                DECLARE @IllnessHealthy INT = (SELECT TOP 1 [illness_id] FROM[tree_illnesses] WHERE [illness_name] = N'Healthy Rice Leaf');
                DECLARE @IllnessBlast INT = (SELECT TOP 1 [illness_id] FROM [tree_illnesses] WHERE[illness_name] = N'Leaf Blast');

                -- 4. Insert Treatment Solutions mới (CARE & MEDICINE)
                IF @StageDeNhanh IS NOT NULL
                BEGIN
                    IF @IllnessBlight IS NOT NULL
                    BEGIN
                        INSERT INTO [treatment_solutions] (illness_id, illness_stage_id, solution_name, solution_type, description, tree_stage_id, min_confidence, priority, created_at)
                        VALUES
                        (@IllnessBlight, NULL, N'Kasugamycin', N'MEDICINE', N'Thuốc kháng sinh đặc trị vi khuẩn gây bạc lá', @StageDeNhanh, 0.7, 1, GETDATE()),
                        (@IllnessBlight, NULL, N'Streptomycin sulfate', N'MEDICINE', N'Kháng sinh kiểm soát vi khuẩn', @StageDeNhanh, 0.7, 2, GETDATE()),
                        (@IllnessBlight, NULL, N'Copper hydroxide', N'MEDICINE', N'Thuốc gốc đồng giúp diệt khuẩn', @StageDeNhanh, 0.7, 3, GETDATE()),
                        (@IllnessBlight, NULL, N'Giảm bón đạm', N'CARE', N'Hạn chế phân đạm, tăng kali để giảm bệnh', @StageDeNhanh, 0.5, 1, GETDATE()),
                        (@IllnessBlight, NULL, N'Quản lý nước', N'CARE', N'Không để ruộng quá ngập nước', @StageDeNhanh, 0.5, 2, GETDATE()),
                        (@IllnessBlight, NULL, N'Dùng giống kháng bệnh', N'CARE', N'Chọn giống lúa có khả năng kháng vi khuẩn', @StageDeNhanh, 0.5, 3, GETDATE());
                    END

                    IF @IllnessBrownSpot IS NOT NULL
                    BEGIN
                        INSERT INTO [treatment_solutions] (illness_id, illness_stage_id, solution_name, solution_type, description, tree_stage_id, min_confidence, priority, created_at)
                        VALUES
                        (@IllnessBrownSpot, NULL, N'Mancozeb', N'MEDICINE', N'Thuốc nấm phổ rộng', @StageDeNhanh, 0.7, 1, GETDATE()),
                        (@IllnessBrownSpot, NULL, N'Propiconazole', N'MEDICINE', N'Thuốc nấm nội hấp', @StageDeNhanh, 0.7, 2, GETDATE()),
                        (@IllnessBrownSpot, NULL, N'Carbendazim', N'MEDICINE', N'Thuốc trị nấm hiệu quả', @StageDeNhanh, 0.7, 3, GETDATE()),
                        (@IllnessBrownSpot, NULL, N'Bón phân cân đối', N'CARE', N'Tăng kali để tăng sức đề kháng', @StageDeNhanh, 0.5, 1, GETDATE()),
                        (@IllnessBrownSpot, NULL, N'Gieo sạ thưa', N'CARE', N'Tránh mật độ dày gây ẩm độ cao', @StageDeNhanh, 0.5, 2, GETDATE()),
                        (@IllnessBrownSpot, NULL, N'Cải thiện thoát nước', N'CARE', N'Tránh đọng nước lâu', @StageDeNhanh, 0.5, 3, GETDATE());
                    END

                    IF @IllnessHealthy IS NOT NULL
                    BEGIN
                        INSERT INTO [treatment_solutions] (illness_id, illness_stage_id, solution_name, solution_type, description, tree_stage_id, min_confidence, priority, created_at)
                        VALUES
                        (@IllnessHealthy, NULL, N'Không cần thuốc', N'MEDICINE', N'Lá khỏe mạnh không cần xử lý thuốc', @StageDeNhanh, 0.3, 1, GETDATE()),
                        (@IllnessHealthy, NULL, N'Bón NPK hợp lý', N'CARE', N'Cung cấp đủ dinh dưỡng cho cây', @StageDeNhanh, 0.5, 1, GETDATE()),
                        (@IllnessHealthy, NULL, N'Kiểm tra định kỳ', N'CARE', N'Phát hiện sớm sâu bệnh', @StageDeNhanh, 0.5, 2, GETDATE()),
                        (@IllnessHealthy, NULL, N'Luân canh cây trồng', N'CARE', N'Giảm tích tụ mầm bệnh', @StageDeNhanh, 0.5, 3, GETDATE());
                    END

                    IF @IllnessBlast IS NOT NULL
                    BEGIN
                        INSERT INTO [treatment_solutions] (illness_id, illness_stage_id, solution_name, solution_type, description, tree_stage_id, min_confidence, priority, created_at)
                        VALUES
                        (@IllnessBlast, NULL, N'Tricyclazole', N'MEDICINE', N'Thuốc đặc trị đạo ôn', @StageDeNhanh, 0.8, 1, GETDATE()),
                        (@IllnessBlast, NULL, N'Isoprothiolane', N'MEDICINE', N'Thuốc trị nấm đạo ôn', @StageDeNhanh, 0.8, 2, GETDATE()),
                        (@IllnessBlast, NULL, N'Azoxystrobin', N'MEDICINE', N'Thuốc nấm phổ rộng', @StageDeNhanh, 0.8, 3, GETDATE()),
                        (@IllnessBlast, NULL, N'Giảm đạm', N'CARE', N'Hạn chế bón đạm để tránh bùng phát bệnh', @StageDeNhanh, 0.6, 1, GETDATE()),
                        (@IllnessBlast, NULL, N'Quản lý ẩm độ', N'CARE', N'Tránh ruộng quá ẩm kéo dài', @StageDeNhanh, 0.6, 2, GETDATE()),
                        (@IllnessBlast, NULL, N'Phun sớm', N'CARE', N'Xử lý ngay khi phát hiện bệnh', @StageDeNhanh, 0.6, 3, GETDATE());
                    END
                END;
                """);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                -- Xóa data mới
                DELETE FROM [treatment_solutions] WHERE [solution_type] IN (N'CARE', N'MEDICINE');
                DELETE FROM [tree_stages] WHERE [stage_name] IN (N'Nảy mầm', N'Mạ', N'Đẻ nhánh', N'Làm đòng', N'Trổ bông', N'Chín');
                """);
        }
    }
}