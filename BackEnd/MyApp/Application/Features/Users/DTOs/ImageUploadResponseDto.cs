namespace MyApp.Application.Features.Users.DTOs
{
    public class ImageUploadResponseDto
    {
        public int UploadId { get; set; }
        public int UserId { get; set; }
        public string? OriginalFilename { get; set; }
        public string? StoredFilename { get; set; }
        public string? FilePath { get; set; }
        public long? FileSize { get; set; }
        public string? MimeType { get; set; }
        public int? ImageWidth { get; set; }
        public int? ImageHeight { get; set; }
        public string? UploadStatus { get; set; }
        public DateTime? UploadedAt { get; set; }
    }
}
