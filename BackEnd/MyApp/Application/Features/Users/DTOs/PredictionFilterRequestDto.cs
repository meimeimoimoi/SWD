using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Users.DTOs
{
    /// <summary>
    /// Filter/search parameters for prediction history
    /// </summary>
    public class PredictionFilterRequestDto
    {
        // --- Tìm ki?m theo tên b?nh ---
        public string? IllnessName { get; set; }

        // --- L?c theo ID b?nh c? th? ---
        public int? IllnessId { get; set; }

        // --- L?c theo m?c ?? nghiêm tr?ng (Low/Medium/High/Critical) ---
        public string? Severity { get; set; }

        // --- L?c theo kho?ng ?? tin c?y ---
        [Range(0, 1, ErrorMessage = "MinConfidence must be between 0 and 1")]
        public decimal? MinConfidence { get; set; }

        [Range(0, 1, ErrorMessage = "MaxConfidence must be between 0 and 1")]
        public decimal? MaxConfidence { get; set; }

        // --- L?c theo kho?ng th?i gian chu?n ?oán ---
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }

        // --- Phân trang ---
        [Range(1, int.MaxValue, ErrorMessage = "Page must be greater than 0")]
        public int Page { get; set; } = 1;

        [Range(1, 100, ErrorMessage = "PageSize must be between 1 and 100")]
        public int PageSize { get; set; } = 10;

        // --- S?p x?p ---
        // Các giá tr? h?p l?: "date", "confidence", "illnessname", "severity"
        public string SortBy { get; set; } = "date";

        // "asc" ho?c "desc"
        public string SortOrder { get; set; } = "desc";
    }
}
