using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.TreeIllnesses.DTOs
{

    public class CreateTreeIllnessDto
    {
        [Required(ErrorMessage = "Illness name is required")]
        [StringLength(255, MinimumLength = 3, ErrorMessage = "Illness name must be between 3 and 255 characters")]
        public string IllnessName { get; set; } = null!;
       
        [MaxLength(255, ErrorMessage = "Scientific name cannot exceed 255 characters")]
        public string? ScientificName { get; set; }
        public string? Description { get; set; }
        public string? Symptoms { get; set; }
        public string? Causes { get; set; }
       
        [Required(ErrorMessage = "Severity is required")]
        [AllowedValues("Low", "Medium", "High", "Critical", 
            ErrorMessage = "Severity must be one of: Low, Medium, High, Critical")]
        public string Severity { get; set; } = null!;
    }
}
