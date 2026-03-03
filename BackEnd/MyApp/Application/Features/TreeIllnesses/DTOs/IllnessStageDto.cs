using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.TreeIllnesses.DTOs
{
    public class IllnessStageDto
    {

        [Required(ErrorMessage = "Stage name is required")]
        [StringLength(255, MinimumLength = 3, ErrorMessage = "Stage name must be between 3 and 255 characters")]
        public string StageName { get; set; } = null!;

        [MaxLength(1000, ErrorMessage = "Description cannot exceed 1000 characters")]
        public string? Description { get; set; }

        [MaxLength(2000, ErrorMessage = "Symptoms cannot exceed 2000 characters")]
        public string? Symptoms { get; set; }
    }
}
