using System;
using System.Collections.Generic;

namespace MyApp.Application.Features.Cart.DTOs
{
    public class CartDto
    {
        public int CartId { get; set; }
        public int UserId { get; set; }
        public List<CartItemDto> Items { get; set; } = new();
    }

    public class CartItemDto
    {
        public int CartItemId { get; set; }
        public int SolutionId { get; set; }
        public string? SolutionName { get; set; }
        public string? SolutionType { get; set; }
        public string? Description { get; set; }
        public string? ImageUrl { get; set; }
        public DateTime? AddedAt { get; set; }
        public int Quantity { get; set; }
    }

    public class AddToCartDto
    {
        public int UserId { get; set; }
        public int SolutionId { get; set; }
        public int Quantity { get; set; } = 1;
    }
}
