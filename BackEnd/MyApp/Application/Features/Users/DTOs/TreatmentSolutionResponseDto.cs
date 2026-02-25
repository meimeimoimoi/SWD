namespace MyApp.Application.Features.Users.DTOs
{
    public class TreatmentSolutionResponseDto
    {
        public int SolutionId { get; set; }

        // Điều kiện áp dụng thuốc
        public string? SolutionName { get; set; }
        public string? SolutionType { get; set; }        // Chemical, Biological, Cultural
        public string? Description { get; set; }         // ⭐ MÔ TẢ THUỐC CHI TIẾT
        public int? Priority { get; set; }

        // Thông tin bệnh
        public int IllnessId { get; set; }
        public string? IllnessName { get; set; }
        public string? IllnessSeverity { get; set; }

        // Giai đoạn cây
        public int TreeStageId { get; set; }
        public string? TreeStageName { get; set; }

        // Conditions
        public decimal? MinConfidence { get; set; }
        public List<SolutionConditionDto>? Conditions { get; set; }

        // Metadata
        public DateTime? CreatedAt { get; set; }
    }
}
