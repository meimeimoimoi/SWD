using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Trees.DTOs;

public class CreateTreeDto
{
    [Required(ErrorMessage = "Tree name is required")]
    [MaxLength(255)]
    public string TreeName { get; set; } = null!;

    [MaxLength(255)]
    public string? ScientificName { get; set; }

    public string? Description { get; set; }

    [MaxLength(500)]
    public string? ImagePath { get; set; }
}
