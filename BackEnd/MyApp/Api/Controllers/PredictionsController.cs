using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Predictions.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PredictionsController : ControllerBase
{
    private readonly IPredictionService _predictionService;

    public PredictionsController(IPredictionService predictionService)
    {
        _predictionService = predictionService;
    }

    [HttpPost("run")]
    public async Task<IActionResult> RunPrediction([FromBody] PredictionRequestDto request)
    {
        try
        {
            var result = await _predictionService.RunPredictionAsync(request);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetPrediction(int id)
    {
        var result = await _predictionService.GetPredictionByIdAsync(id);
        return result == null ? NotFound() : Ok(result);
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory()
    {
        var result = await _predictionService.GetPredictionHistoryAsync();
        return Ok(result);
    }
}
