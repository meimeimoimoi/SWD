using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Cart.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services
{
    public class CartService : ICartService
    {
        private readonly AppDbContext _context;

        public CartService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<CartDto?> GetCartByUserIdAsync(int userId)
        {
            var cart = await _context.Carts
                .Include(c => c.CartItems)
                    .ThenInclude(i => i.Solution)
                        .ThenInclude(s => s.Images)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null) return null;

            return new CartDto
            {
                CartId = cart.CartId,
                UserId = cart.UserId,
                Items = cart.CartItems.Select(i => new CartItemDto
                {
                    CartItemId = i.CartItemId,
                    SolutionId = i.SolutionId,
                    SolutionName = i.Solution?.SolutionName,
                    SolutionType = i.Solution?.SolutionType,
                    Description = i.Solution?.Description,
                    ImageUrl = i.Solution?.Images
                        .OrderBy(img => img.DisplayOrder)
                        .FirstOrDefault()?.ImageUrl,
                    ShoppeUrl = i.Solution?.ShoppeUrl,
                    AddedAt = i.AddedAt,
                    Quantity = i.Quantity
                }).ToList()
            };
        }

        public async Task<bool> AddToCartAsync(AddToCartDto dto)
        {
            // Validate solution exists to avoid FK constraint violations
            var solution = await _context.TreatmentSolutions.FindAsync(dto.SolutionId);
            if (solution == null)
            {
                return false;
            }
            var cart = await _context.Carts.FirstOrDefaultAsync(c => c.UserId == dto.UserId);
            if (cart == null)
            {
                cart = new Cart { UserId = dto.UserId };
                _context.Carts.Add(cart);
                await _context.SaveChangesAsync();
            }

            var item = await _context.CartItems.FirstOrDefaultAsync(i => i.CartId == cart.CartId && i.SolutionId == dto.SolutionId);
            if (item == null)
            {
                _context.CartItems.Add(new CartItem 
                { 
                    CartId = cart.CartId, 
                    SolutionId = dto.SolutionId, 
                    Quantity = dto.Quantity > 0 ? dto.Quantity : 1 
                });
            }
            else
            {
                item.Quantity += dto.Quantity > 0 ? dto.Quantity : 1;
            }
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> RemoveFromCartAsync(int cartItemId)
        {
            var item = await _context.CartItems.FindAsync(cartItemId);
            if (item != null)
            {
                _context.CartItems.Remove(item);
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<bool> SolutionExistsAsync(int solutionId)
        {
            return await _context.TreatmentSolutions.AnyAsync(ts => ts.SolutionId == solutionId);
        }
    }
}
