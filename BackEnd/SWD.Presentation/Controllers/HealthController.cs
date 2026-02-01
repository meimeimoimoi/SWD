using Microsoft.AspNetCore.Mvc;

namespace SWD.Presentation.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            return Ok(new { status = "Healthy", message = "API is running", timestamp = DateTime.UtcNow });
        }
    }
}
