using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Models.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ModelsController : ControllerBase
{
    private readonly IModelVersionService _modelService;

    public ModelsController(IModelVersionService modelService)
    {
        _modelService = modelService;
    }

    [HttpGet]
    public async Task<IActionResult> GetModels()
    {
        var result = await _modelService.GetAllModelsAsync();
        return Ok(result);
    }

    [HttpPut("{id}/activate")]
    public async Task<IActionResult> ActivateModel(int id, [FromBody] ActivateModelDto dto)
    {
        var success = await _modelService.ActivateModelAsync(id, dto.IsActive);
        return success ? Ok() : NotFound();
    }

    [HttpPut("{id}/default")]
    public async Task<IActionResult> SetDefaultModel(int id)
    {
        var success = await _modelService.SetDefaultModelAsync(id);
        return success ? Ok() : NotFound();
    }
}
