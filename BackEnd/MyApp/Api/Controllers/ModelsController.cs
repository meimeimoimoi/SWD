using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Models.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Technical,Admin")]
public class ModelsController : ControllerBase
{
    private readonly IModelService _modelService;
    private readonly ILogger<ModelsController> _logger;

    public ModelsController(IModelService modelService, ILogger<ModelsController> logger)
    {
        _modelService = modelService;
        _logger = logger;
    }

    /// <summary>
    /// Get all model versions
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAllModels()
    {
        try
        {
            var models = await _modelService.GetAllModelsAsync();
            return Ok(new
            {
                success = true,
                message = "Models retrieved successfully",
                data = models
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all models");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving models",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get model by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetModelById(int id)
    {
        try
        {
            var model = await _modelService.GetModelByIdAsync(id);
            
            if (model == null)
                return NotFound(new
                {
                    success = false,
                    message = $"Model with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = "Model retrieved successfully",
                data = model
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting model {ModelId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving the model",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get default/active model
    /// </summary>
    [HttpGet("default")]
    public async Task<IActionResult> GetDefaultModel()
    {
        try
        {
            var model = await _modelService.GetDefaultModelAsync();
            
            if (model == null)
                return NotFound(new
                {
                    success = false,
                    message = "No default model found"
                });

            return Ok(new
            {
                success = true,
                message = "Default model retrieved successfully",
                data = model
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting default model");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving the default model",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Activate a model version
    /// </summary>
    [HttpPut("{id}/activate")]
    public async Task<IActionResult> ActivateModel(int id)
    {
        try
        {
            var result = await _modelService.ActivateModelAsync(id);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Model with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Model {id} activated successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error activating model {ModelId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while activating the model",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Deactivate a model version
    /// </summary>
    [HttpPut("{id}/deactivate")]
    public async Task<IActionResult> DeactivateModel(int id)
    {
        try
        {
            var result = await _modelService.DeactivateModelAsync(id);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Model with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Model {id} deactivated successfully"
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new
            {
                success = false,
                message = ex.Message
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deactivating model {ModelId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while deactivating the model",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Set a model as default
    /// </summary>
    [HttpPut("{id}/set-default")]
    public async Task<IActionResult> SetDefaultModel(int id)
    {
        try
        {
            var result = await _modelService.SetDefaultModelAsync(id);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Model with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Model {id} set as default successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting default model {ModelId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while setting the default model",
                error = ex.Message
            });
        }
    }
}
