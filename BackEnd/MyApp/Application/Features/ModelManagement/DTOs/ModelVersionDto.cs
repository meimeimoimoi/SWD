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
        public string? FilePath { get; set; }
    }

    public class UploadModelDto
    {
        [Required(ErrorMessage = "Model name is required.")]
        public string ModelName { get; set; } = null!;

        [Required(ErrorMessage = "Version is required.")]
        public string Version { get; set; } = null!;

        public string? ModelType { get; set; } = "mobilenetv3";

        public string? Description { get; set; }

        /// <summary>
        /// .onnx file — required, only .onnx extension is accepted.
        /// </summary>
        [Required(ErrorMessage = "Model file (.onnx) is required.")]
        public IFormFile ModelFile { get; set; } = null!;
    }
}
