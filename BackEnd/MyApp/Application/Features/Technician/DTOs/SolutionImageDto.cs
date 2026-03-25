using System;

namespace MyApp.Application.Features.Technician.DTOs
{
    public class SolutionImageDto
    {
        public int ImageId { get; set; }
        public string ImageUrl { get; set; } = null!;
        public int DisplayOrder { get; set; }
        public DateTime UploadedAt { get; set; }
        public long? FileSize { get; set; }
        public int? Width { get; set; }
        public int? Height { get; set; }
    }
}
