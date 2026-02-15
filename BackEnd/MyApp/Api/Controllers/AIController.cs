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
    /// Preprocess an uploaded image (resize, normalize) for Technical staff
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
}
