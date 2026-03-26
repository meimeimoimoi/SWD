using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Technician.DTOs
{
    public class IllnessDto
    {
        public int IllnessId { get; set; }
        public string? IllnessName { get; set; }
        public string? ScientificName { get; set; }
        public string? Description { get; set; }
        public string? Symptoms { get; set; }
        public string? Causes { get; set; }
        public string? Severity { get; set; }
        public DateTime? CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class CreateIllnessDto
    {
        [Required(ErrorMessage = "Illness name is required.")]
        [StringLength(255, MinimumLength = 1, ErrorMessage = "Illness name must be between 1 and 255 characters.")]
        public string IllnessName { get; set; } = string.Empty;

        [StringLength(255, ErrorMessage = "Scientific name must not exceed 255 characters.")]
        public string? ScientificName { get; set; }

        public string? Description { get; set; }

        public string? Symptoms { get; set; }

        public string? Causes { get; set; }

        [StringLength(50, ErrorMessage = "Severity must not exceed 50 characters.")]
        public string? Severity { get; set; }
    }

    public class UpdateIllnessDto
    {
        [StringLength(255, MinimumLength = 1, ErrorMessage = "Illness name must be between 1 and 255 characters.")]
        public string? IllnessName { get; set; }

        [StringLength(255, ErrorMessage = "Scientific name must not exceed 255 characters.")]
        public string? ScientificName { get; set; }

        public string? Description { get; set; }

        public string? Symptoms { get; set; }

        public string? Causes { get; set; }

        [StringLength(50, ErrorMessage = "Severity must not exceed 50 characters.")]
        public string? Severity { get; set; }
    }

    public class AssignIllnessToTreeDto
    {
        [Required(ErrorMessage = "TreeId is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "TreeId must be a positive integer.")]
        public int TreeId { get; set; }
    }

    public class CreateTreatmentDto
    {
        [Required(ErrorMessage = "IllnessId is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "IllnessId must be a positive integer.")]
        public int IllnessId { get; set; }

        [Required(ErrorMessage = "TreeStageId is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "TreeStageId must be a positive integer.")]
        public int TreeStageId { get; set; }

        [Required(ErrorMessage = "Solution name is required.")]
        [StringLength(255, MinimumLength = 1, ErrorMessage = "Solution name must be between 1 and 255 characters.")]
        public string SolutionName { get; set; } = string.Empty;

        [StringLength(100, ErrorMessage = "Solution type must not exceed 100 characters.")]
        public string? SolutionType { get; set; }

        public string? Description { get; set; }

        [Range(0, 1, ErrorMessage = "MinConfidence must be between 0 and 1.")]
        public decimal? MinConfidence { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Priority must be a positive integer.")]
        public int? Priority { get; set; }

        public string? Ingredients { get; set; }

        public string? ShoppeUrl { get; set; }

        public string? Instructions { get; set; }

        // Thêm thuộc tính nhận danh sách ảnh khi tạo treatment
        public List<IFormFile>? Images { get; set; }
    }

    public class AssignTreatmentToIllnessDto
    {
        [Required(ErrorMessage = "IllnessId is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "IllnessId must be a positive integer.")]
        public int IllnessId { get; set; }
    }
}
