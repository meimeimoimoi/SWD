using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Cart.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/cart")]
    [ApiController]
    [Authorize]
    public class CartController : ControllerBase
    {
        private readonly ICartService _cartService;

        public CartController(ICartService cartService)
        {
            _cartService = cartService;
        }

        [HttpGet]
        public async Task<IActionResult> GetUserCart()
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value;
            if (!int.TryParse(userIdClaim, out var userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng." });

            var cart = await _cartService.GetCartByUserIdAsync(userId);
            if (cart == null)
            {
                return Ok(new { success = true, data = new { items = new List<object>() } });
            }
            return Ok(new { success = true, data = cart });
        }

        [HttpPost("add")]
        public async Task<IActionResult> AddToCart([FromBody] AddToCartDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            // Ensure user id comes from token rather than client payload
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value;
            if (!int.TryParse(userIdClaim, out var uid))
            {
                return Unauthorized(new { success = false, message = "Không xác định được người dùng." });
            }
            dto.UserId = uid;

            if (dto.SolutionId <= 0)
            {
                return BadRequest(new { success = false, message = "solutionId is required." });
            }

            // Validate solution exists
            var solExists = await _cartService.SolutionExistsAsync(dto.SolutionId);
            if (!solExists)
            {
                return NotFound(new { success = false, message = $"Solution with id {dto.SolutionId} not found." });
            }

            var result = await _cartService.AddToCartAsync(dto);
            return Ok(new { success = result, message = result ? "Đã thêm vào giỏ hàng." : "Không thể thêm vào giỏ hàng." });
        }

        [HttpDelete("item/{cartItemId}")]
        public async Task<IActionResult> RemoveFromCart(int cartItemId)
        {
            var result = await _cartService.RemoveFromCartAsync(cartItemId);
            if (!result) return NotFound(new { success = false, message = "Không tìm thấy mục trong giỏ hàng." });
            return Ok(new { success = true, message = "Đã xóa khỏi giỏ hàng." });
        }
    }
}
