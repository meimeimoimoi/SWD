using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Trees.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TreesController : ControllerBase
{
    private readonly ITreeService _treeService;

    public TreesController(ITreeService treeService)
    {
        _treeService = treeService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var result = await _treeService.GetAllTreesAsync();
        return Ok(result);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTreeDto dto)
    {
        var id = await _treeService.CreateTreeAsync(dto);
        return CreatedAtAction(nameof(GetAll), new { id }, new { treeId = id });
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateTreeDto dto)
    {
        var success = await _treeService.UpdateTreeAsync(id, dto);
        return success ? Ok() : NotFound();
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _treeService.DeleteTreeAsync(id);
        return success ? NoContent() : NotFound();
    }
}
