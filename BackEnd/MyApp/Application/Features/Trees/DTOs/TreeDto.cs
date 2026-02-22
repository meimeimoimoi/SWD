namespace MyApp.Application.Features.Trees.DTOs;

public class TreeDto
{
    public int TreeId { get; set; }
    public string TreeName { get; set; } = null!;
    public string? ScientificName { get; set; }
    public string? Description { get; set; }
    public string? ImagePath { get; set; }
    public DateTime? CreatedAt { get; set; }
    public List<TreeIllnessDto>? Illnesses { get; set; }
}

public class TreeIllnessDto
{
    public int IllnessId { get; set; }
    public string IllnessName { get; set; } = null!;
    public string? Severity { get; set; }
}
