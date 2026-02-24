namespace MyApp.Application.Features.Trees.DTOs;

public class CreateTreeDto
{
    public string TreeName { get; set; } = null!;
    public string? ScientificName { get; set; }
    public string? Description { get; set; }
}
