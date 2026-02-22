using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Solutions.DTOs;

public class UpdateSolutionDto
{
    [Required(ErrorMessage = "Solution name is required")]
    [MaxLength(255)]
    public string SolutionName { get; set; } = null!;

    [Required(ErrorMessage = "Solution type is required")]
    [MaxLength(100)]
    [RegularExpression("^(BIOLOGICAL|CHEMICAL|CULTURAL)$", ErrorMessage = "Solution type must be BIOLOGICAL, CHEMICAL, or CULTURAL")]
    public string SolutionType { get; set; } = null!;

    public string? Description { get; set; }

    [Required(ErrorMessage = "Illness ID is required")]
    public int IllnessId { get; set; }

    [Required(ErrorMessage = "Tree stage ID is required")]
    public int TreeStageId { get; set; }

    [Range(0, int.MaxValue)]
    public int? Priority { get; set; }

    [Range(0.0, 1.0, ErrorMessage = "MinConfidence must be between 0 and 1")]
    public decimal? MinConfidence { get; set; }
}
