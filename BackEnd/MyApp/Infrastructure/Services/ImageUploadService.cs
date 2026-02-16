using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace MyApp.Infrastructure.Services
{
    public class ImageUploadService:IImageUploadService
    {
        private readonly ImageUploadRepository _imageUploadRepository;
        private readonly ILogger<ImageUploadService> _logger;
        private readonly IWebHostEnvironment _environment;
        private readonly string _uploadPath;

        //Allowed image types
        private readonly string[] _allowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };
        private readonly string[] _allowedMimeTypes = { "image/jpeg", "image/png", "image/gif", "image/bmp" };
        private const long MaxFileSize = 10 * 1024 * 1024; // 10 MB

        public ImageUploadService(ImageUploadRepository imageUploadRepository, 
            ILogger<ImageUploadService> logger,
            IWebHostEnvironment environment)
        {
            _imageUploadRepository = imageUploadRepository;
            _logger = logger;
            _environment = environment;

            //Create uploads directory if it doesn't exist
            _uploadPath = Path.Combine(_environment.ContentRootPath, "uploads", "images");
            if(!Directory.Exists(_uploadPath))
            {
                Directory.CreateDirectory(_uploadPath);
                _logger.LogInformation("Created upload directory: {UploadPath}", _uploadPath);
            }
        }

        public async Task<ImageUploadResponseDto> UploadImageAsync(int userId, IFormFile imageFile)
        {
            try
            {
                //Validate file 
                ValidateImageFile(imageFile);

                _logger.LogInformation("Uploading image for user {UserId}: {FileName}", userId, imageFile.FileName);

                //Generate unique filename
                var fileExtension = Path.GetExtension(imageFile.FileName).ToLowerInvariant();
                var storedFilename = $"{Guid.NewGuid()}{fileExtension}";
                var filePath = Path.Combine(_uploadPath, storedFilename);

                //Get image dimensions and save
                int width = 0, height = 0;
                using (var image = await Image.LoadAsync(imageFile.OpenReadStream()))
                {
                    width = image.Width;
                    height = image.Height;

                    //Optionally resize if too large
                    if(width >2048 || height > 2048)
                    {
                        _logger.LogInformation("Resizing large image from {Width}x{Height}", width, height);
                        // Mutate(): directly edit the image
                        image.Mutate(x => x.Resize(new ResizeOptions
                        {
                            Size = new Size(2048, 2048),
                            Mode = ResizeMode.Max // ResizeMode.Max: Resize the image so that it does not exceed 2048x2048 pixels,but still maintain the original aspect ratio.
                        }));
                        width = image.Width;
                        height = image.Height;
                    }

                    //Save image
                    await image.SaveAsync(filePath);
                }
                //Create database record
                var imageUpload = new ImageUpload
                {
                    UserId = userId,
                    OriginalFilename = imageFile.FileName,
                    StoredFilename = storedFilename,
                    FilePath = filePath,
                    FileSize = imageFile.Length,
                    MimeType = imageFile.ContentType,
                    ImageWidth = width,
                    ImageHeight = height,
                    UploadStatus = "Pending",
                    UploadedAt = DateTime.UtcNow
                };

                var savedImage = await _imageUploadRepository.AddImageAsync(imageUpload);

                _logger.LogInformation("Image uploaded successfully: UploadId={UploadId}, Size={FileSize}KB",
                    savedImage.UploadId, imageFile.Length / 1024);

                return MapToDto(savedImage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading image for user {UserId}", userId);
                throw;
            }
        }

        public async Task<ImageUploadResponseDto?> GetImageByIdAsync(int uploadId)
        {
            var image = await _imageUploadRepository.GetImageByIdAsync(uploadId);
            return image != null ? MapToDto(image) : null;
        }

        public async Task<List<ImageUploadResponseDto>> GetUserImagesAsync(int userId)
        {
            var images = await _imageUploadRepository.GetImagesByUserIdAsync(userId);
            return images.Select(MapToDto).ToList();
        }

        public async Task<byte[]?> GetImageBytesAsync(int uploadId)
        {
            try
            {
                var image = await _imageUploadRepository.GetImageByIdAsync(uploadId);
                
                if (image == null || string.IsNullOrEmpty(image.FilePath))
                    return null;

                if (!File.Exists(image.FilePath))
                {
                    _logger.LogWarning("Image file not found: {FilePath}", image.FilePath);
                    return null;
                }

                return await File.ReadAllBytesAsync(image.FilePath);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error reading image bytes for {UploadId}", uploadId);
                throw;
            }
        }

        private void ValidateImageFile(IFormFile file)
        {
            if(file == null || file.Length == 0)
            {
                throw new ArgumentException("File is empty or null");
            }

            if(file.Length > MaxFileSize)
            {
                throw new ArgumentException($"File size exceeds the maximum allowed size of {MaxFileSize / (1024 * 1024)}MB");
            }

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if(!_allowedExtensions.Contains(extension))
            {
                throw new ArgumentException($"File type '{extension}' is not allowed. Allowed types: {string.Join(", ", _allowedExtensions)}");
            }

            if (!_allowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()))
            {
                throw new ArgumentException($"MIME type '{file.ContentType}' is not allowed");
            }
        }

        private ImageUploadResponseDto MapToDto(ImageUpload image)
        {
            return new ImageUploadResponseDto
            {
                UploadId = image.UploadId,
                UserId = image.UserId,
                OriginalFilename = image.OriginalFilename,
                StoredFilename = image.StoredFilename,
                FilePath = image.FilePath,
                FileSize = image.FileSize,
                MimeType = image.MimeType,
                ImageWidth = image.ImageWidth,
                ImageHeight = image.ImageHeight,
                UploadStatus = image.UploadStatus,
                UploadedAt = image.UploadedAt
            };
        }
    }
}
