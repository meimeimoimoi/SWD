using Microsoft.AspNetCore.Mvc;
using SWD.Business.DTOs;
using SWD.Business.Interface;

namespace SWD.Presentation.Controllers;

/// <summary>
/// Controller for rice disease detection using ResNet18
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class DiseaseDetectionController : BaseController
{
    private readonly IDiseaseDetectionService _diseaseDetectionService;

    public DiseaseDetectionController(IDiseaseDetectionService diseaseDetectionService)
    {
        _diseaseDetectionService = diseaseDetectionService;
    }

    /// <summary>
    /// Check if the model is loaded and ready
    /// </summary>
    /// <returns>Model status</returns>
    [HttpGet("status")]
    public IActionResult GetModelStatus()
    {
        var isReady = _diseaseDetectionService.IsModelReady();
        return Ok(new
        {
            modelLoaded = isReady,
            message = isReady 
                ? "ResNet18 model is loaded and ready" 
                : "Model not loaded. Please check model file location.",
            timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Predict disease from uploaded image file
    /// </summary>
    /// <param name="file">Image file (JPG, PNG, etc.)</param>
    /// <returns>Prediction result</returns>
    [HttpPost("predict/upload")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> PredictFromUpload([FromForm] IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { error = "No file uploaded" });
        }

        // Validate file type
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".bmp" };
        var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
        
        if (!allowedExtensions.Contains(fileExtension))
        {
            return BadRequest(new 
            { 
                error = "Invalid file type. Only JPG, PNG, and BMP images are allowed." 
            });
        }

        // Validate file size (max 10MB)
        if (file.Length > 10 * 1024 * 1024)
        {
            return BadRequest(new { error = "File size exceeds 10MB limit" });
        }

        try
        {
            // Read image bytes
            using var memoryStream = new MemoryStream();
            await file.CopyToAsync(memoryStream);
            var imageBytes = memoryStream.ToArray();

            // Predict
            var result = await _diseaseDetectionService.PredictDiseaseAsync(imageBytes);

            return Ok(new
            {
                success = true,
                fileName = file.FileName,
                fileSize = file.Length,
                prediction = result
            });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(503, new 
            { 
                error = "Model not available", 
                message = ex.Message 
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new 
            { 
                error = "Internal server error", 
                message = ex.Message 
            });
        }
    }

    /// <summary>
    /// Predict disease from base64 encoded image
    /// </summary>
    /// <param name="request">Request containing base64 image</param>
    /// <returns>Prediction result</returns>
    [HttpPost("predict/base64")]
    public async Task<IActionResult> PredictFromBase64([FromBody] DiseasePredictionRequestDTO request)
    {
        if (string.IsNullOrEmpty(request.ImageData))
        {
            return BadRequest(new { error = "ImageData is required" });
        }

        try
        {
            var result = await _diseaseDetectionService.PredictDiseaseFromBase64Async(request.ImageData);

            return Ok(new
            {
                success = true,
                prediction = result
            });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(503, new 
            { 
                error = "Model not available", 
                message = ex.Message 
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new 
            { 
                error = "Internal server error", 
                message = ex.Message 
            });
        }
    }

    /// <summary>
    /// Get list of detectable diseases
    /// </summary>
    /// <returns>List of disease labels</returns>
    [HttpGet("diseases")]
    public IActionResult GetDiseaseList()
    {
        var diseases = new[]
        {
            new { id = 0, name = "Healthy", description = "Cây lúa khỏe mạnh" },
            new { id = 1, name = "Bacterial Leaf Blight", description = "Bạc lá do vi khuẩn" },
            new { id = 2, name = "Brown Spot", description = "Đốm nâu" },
            new { id = 3, name = "Leaf Smut", description = "Đen lép hạt" },
            new { id = 4, name = "Blast", description = "Đạo ôn" }
        };

        return Ok(new
        {
            totalDiseases = diseases.Length,
            diseases = diseases
        });
    }
}
