using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.TreeStages.DTOs
{
 
    public class UpdateTreeStageDto
    {
  
        [StringLength(255, MinimumLength = 2, ErrorMessage = "Stage name must be between 2 and 255 characters")]
        public string? StageName { get; set; }
        public string? Description { get; set; }
    }
}
