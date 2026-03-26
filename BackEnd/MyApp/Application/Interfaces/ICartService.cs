using MyApp.Application.Features.Cart.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface ICartService
    {
        Task<CartDto?> GetCartByUserIdAsync(int userId);
        Task<bool> AddToCartAsync(AddToCartDto dto);
        Task<bool> RemoveFromCartAsync(int cartItemId);
        Task<bool> SolutionExistsAsync(int solutionId);
    }
}
