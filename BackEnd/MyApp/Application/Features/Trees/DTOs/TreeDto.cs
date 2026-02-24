namespace MyApp.Application.Features.Trees.DTOs;

public class TreeDto
{
    public int TreeId { get; set; }
    public string TreeName { get; set; } = null!;
    public string? ScientificName { get; set; }
    public string? Description { get; set; }
}
