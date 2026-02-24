namespace MyApp.Application.Features.Illnesses.DTOs;

public class IllnessDto
{
    public int IllnessId { get; set; }
    public string IllnessName { get; set; } = null!;
    public string? ScientificName { get; set; }
    public string? Severity { get; set; }
    public string? Description { get; set; }
}
