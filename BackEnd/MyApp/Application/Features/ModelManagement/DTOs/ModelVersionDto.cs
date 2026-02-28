using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.ModelManagement.DTOs
{
    public class ModelVersionDto
    {
        public int ModelVersionId { get; set; }
        public string ModelName { get; set; } = null!;
        public string Version { get; set; } = null!;
        public string? ModelType { get; set; }
        public string? Description { get; set; }
        public bool? IsActive { get; set; }
        public bool? IsDefault { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    public class UploadModelDto
    {
        [Required]
        public string ModelName { get; set; } = null!;

        [Required]
        public string Version { get; set; } = null!;

        public string? ModelType { get; set; } = "resnet18";

        public string? Description { get; set; }

        public bool IsActive { get; set; } = true;

        public bool IsDefault { get; set; } = false;

        /// <summary>
        /// Optional: Upload file .onnx tr?c ti?p
        /// </summary>
        public IFormFile? ModelFile { get; set; }
    }
}
