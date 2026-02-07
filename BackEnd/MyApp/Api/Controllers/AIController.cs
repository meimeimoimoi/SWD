using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.AI.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Technical,Admin")]
public class AIController : ControllerBase
{
    private readonly IAIService _aiService;
    private readonly ILogger<AIController> _logger;

    public AIController(IAIService aiService, ILogger<AIController> logger)
    {
        _aiService = aiService;
        _logger = logger;
    }

    /// <summary>
    /// Preprocess an uploaded image (resize, normalize)
    /// </summary>
    [HttpPost("preprocess")]
    public async Task<IActionResult> PreprocessImage([FromBody] PreprocessImageRequestDto request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new
                {
                    success = false,
                    message = "Invalid input",
                    errors = ModelState.Values.SelectMany(v => v.Errors.Select(e => e.ErrorMessage))
                });

            var result = await _aiService.PreprocessImageAsync(request);
            
            return Ok(new
            {
                success = true,
                message = "Image preprocessed successfully",
                data = result
            });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid operation during image preprocessing");
            return BadRequest(new
            {
                success = false,
                message = ex.Message
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error preprocessing image for UploadId: {UploadId}", request.UploadId);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while preprocessing the image",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Run inference on an image to detect tree disease
    /// </summary>
    [HttpPost("inference")]
    public async Task<IActionResult> RunInference([FromBody] InferenceRequestDto request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new
                {
                    success = false,
                    message = "Invalid input",
                    errors = ModelState.Values.SelectMany(v => v.Errors.Select(e => e.ErrorMessage))
                });

            var result = await _aiService.RunInferenceAsync(request);
            
            return Ok(new
            {
                success = true,
                message = "Inference completed successfully",
                data = result
            });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid operation during inference");
            return BadRequest(new
            {
                success = false,
                message = ex.Message
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error running inference for UploadId: {UploadId}", request.UploadId);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while running inference",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Process image and run inference in one step
    /// </summary>
    [HttpPost("process-and-predict")]
    public async Task<IActionResult> ProcessAndPredict([FromBody] InferenceRequestDto request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new
                {
                    success = false,
                    message = "Invalid input",
                    errors = ModelState.Values.SelectMany(v => v.Errors.Select(e => e.ErrorMessage))
                });

            // First preprocess the image
            var preprocessRequest = new PreprocessImageRequestDto
            {
                UploadId = request.UploadId,
                TargetWidth = 224,
                TargetHeight = 224,
                Normalize = true
            };

            var preprocessResult = await _aiService.PreprocessImageAsync(preprocessRequest);
            _logger.LogInformation("Image preprocessed: {ProcessedId}", preprocessResult.ProcessedId);

            // Then run inference
            request.UsePreprocessedImage = true;
            var inferenceResult = await _aiService.RunInferenceAsync(request);
            
            return Ok(new
            {
                success = true,
                message = "Image processed and prediction completed successfully",
                data = new
                {
                    preprocessing = preprocessResult,
                    prediction = inferenceResult
                }
            });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid operation during process and predict");
            return BadRequest(new
            {
                success = false,
                message = ex.Message
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during process and predict for UploadId: {UploadId}", request.UploadId);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while processing and predicting",
                error = ex.Message
            });
        }
    }
}
