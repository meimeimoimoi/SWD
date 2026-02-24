using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Solutions.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SolutionsController : ControllerBase
{
    private readonly ISolutionService _solutionService;

    public SolutionsController(ISolutionService solutionService)
    {
        _solutionService = solutionService;
    }

    [HttpGet("by-prediction/{predictionId}")]
    public async Task<IActionResult> GetByPrediction(int predictionId)
    {
        var result = await _solutionService.GetSolutionsByPredictionAsync(predictionId);
        return result == null ? NotFound() : Ok(result);
    }

    [HttpGet("by-illness/{illnessId}")]
    public async Task<IActionResult> GetByIllness(int illnessId)
    {
        var result = await _solutionService.GetSolutionsByIllnessAsync(illnessId);
        return result == null ? NotFound() : Ok(result);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateSolutionDto dto)
    {
        try
        {
            var id = await _solutionService.CreateSolutionAsync(dto);
            return CreatedAtAction(nameof(GetByPrediction), new { predictionId = id }, new { solutionId = id });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateSolutionDto dto)
    {
        try
        {
            var success = await _solutionService.UpdateSolutionAsync(id, dto);
            return success ? Ok() : NotFound();
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _solutionService.DeleteSolutionAsync(id);
        return success ? NoContent() : NotFound();
    }
}
