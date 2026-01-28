using Microsoft.AspNetCore.Mvc;

namespace SWD.Presentation.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public abstract class BaseController : ControllerBase
    {
        // Common controller functionality can be added here
    }
}
