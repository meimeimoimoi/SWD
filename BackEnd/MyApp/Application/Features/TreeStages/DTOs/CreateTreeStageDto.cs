using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.TreeStages.DTOs
{
    
    public class CreateTreeStageDto
    {
      
        [Required(ErrorMessage = "Stage name is required")]
        [StringLength(255, MinimumLength = 2, ErrorMessage = "Stage name must be between 2 and 255 characters")]
        public string StageName { get; set; } = null!;
        public string? Description { get; set; }
    }
}
