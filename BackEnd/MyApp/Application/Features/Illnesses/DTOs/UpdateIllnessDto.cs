using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Illnesses.DTOs;

public class UpdateIllnessDto
{
    [Required(ErrorMessage = "Illness name is required")]
    [MaxLength(255)]
    public string IllnessName { get; set; } = null!;

    [MaxLength(255)]
    public string? ScientificName { get; set; }

    public string? Description { get; set; }

    public string? Symptoms { get; set; }

    public string? Causes { get; set; }

    [MaxLength(50)]
    public string? Severity { get; set; }
}
