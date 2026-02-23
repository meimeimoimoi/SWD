using Microsoft.IdentityModel.Tokens;
using MyApp.Domain.Entities;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace MyApp.Infrastructure.Services
{
    public class JwtTokenGeneratior
    {
        private readonly IConfiguration _config;

        public JwtTokenGeneratior(IConfiguration config)
        {
            _config = config;
        }

        public string GenerateToken(User user, TimeSpan tokenExpiration, out string jti)
        {
            jti = Guid.NewGuid().ToString();

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, user.Username),
                new Claim(JwtRegisteredClaimNames.Jti, jti),
                new Claim(ClaimTypes.Role, user.Role),
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.Add(tokenExpiration),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public RefreshToken GenerateRefreshToken(string jti)
        {
            var now = DateTime.UtcNow;

            return new RefreshToken
            {
                JtiHash = jti,
                IsRevoked = false,
                CreatedAt = now,
                UpdatedAt = now
            };
            
        }
    }
}
