using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Admin.DTOs
{
    public class TreeStageDto
    {
        public int StageId { get; set; }
        public string? StageName { get; set; }
        public string? Description { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    public class CreateTreeStageDto
    {
        [Required(ErrorMessage = "Stage name is required.")]
        [StringLength(100, MinimumLength = 1, ErrorMessage = "Stage name must be between 1 and 100 characters.")]
        public string StageName { get; set; } = string.Empty;

        [StringLength(500, ErrorMessage = "Description must not exceed 500 characters.")]
        public string? Description { get; set; }
    }

    public class UpdateTreeStageDto
    {
        [StringLength(100, MinimumLength = 1, ErrorMessage = "Stage name must be between 1 and 100 characters.")]
        public string? StageName { get; set; }

        [StringLength(500, ErrorMessage = "Description must not exceed 500 characters.")]
        public string? Description { get; set; }
    }
}
