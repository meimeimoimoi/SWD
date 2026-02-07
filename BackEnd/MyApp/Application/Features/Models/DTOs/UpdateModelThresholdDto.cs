using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Models.DTOs;

public class UpdateModelThresholdDto
{
    [Required]
    [Range(0.0, 1.0, ErrorMessage = "MinConfidence must be between 0.0 and 1.0")]
    public decimal MinConfidence { get; set; }
}
