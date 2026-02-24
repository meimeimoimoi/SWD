using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.TreeIllnessRelations.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/tree-illness")]
[Authorize(Roles = "Admin")]
public class TreeIllnessController : ControllerBase
{
    private readonly ITreeIllnessRelationService _relationService;

    public TreeIllnessController(ITreeIllnessRelationService relationService)
    {
        _relationService = relationService;
    }

    [HttpPost("map")]
    public async Task<IActionResult> Map([FromBody] MapTreeIllnessDto dto)
    {
        try
        {
            await _relationService.MapTreeIllnessAsync(dto);
            return Ok(new { message = "Mapped successfully" });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }

    [HttpDelete("unmap")]
    public async Task<IActionResult> Unmap([FromBody] MapTreeIllnessDto dto)
    {
        var success = await _relationService.UnmapTreeIllnessAsync(dto);
        return success ? NoContent() : NotFound(new { error = "Mapping not found" });
    }
}
