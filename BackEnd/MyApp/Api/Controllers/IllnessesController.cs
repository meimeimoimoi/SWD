using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Illnesses.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class IllnessesController : ControllerBase
{
    private readonly IIllnessService _illnessService;

    public IllnessesController(IIllnessService illnessService)
    {
        _illnessService = illnessService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var result = await _illnessService.GetAllIllnessesAsync();
        return Ok(result);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateIllnessDto dto)
    {
        var id = await _illnessService.CreateIllnessAsync(dto);
        return CreatedAtAction(nameof(GetAll), new { id }, new { illnessId = id });
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateIllnessDto dto)
    {
        var success = await _illnessService.UpdateIllnessAsync(id, dto);
        return success ? Ok() : NotFound();
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _illnessService.DeleteIllnessAsync(id);
        return success ? NoContent() : NotFound();
    }
}
