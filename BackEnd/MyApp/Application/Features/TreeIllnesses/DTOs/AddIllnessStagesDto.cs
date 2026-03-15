using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.TreeIllnesses.DTOs
{
    public class AddIllnessStagesDto
    {
        [Required(ErrorMessage = "At least one stage is required")]
        [MinLength(1, ErrorMessage = "At least one stage is required")]
        public List<IllnessStageDto> Stages { get; set; } = new();
    }
}
