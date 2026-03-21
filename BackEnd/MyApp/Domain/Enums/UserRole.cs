namespace MyApp.Domain.Enums;

/// <summary>Stored as string in the database (role column).</summary>
public enum UserRole
{
    User = 0,
    Admin = 1,
    Technician = 2,
    Staff = 3
}

/// <summary>Constants for <see cref="Microsoft.AspNetCore.Authorization.AuthorizeAttribute.Roles"/>.</summary>
public static class RolePolicy
{
    public const string Admin = nameof(UserRole.Admin);
    public const string User = nameof(UserRole.User);
    public const string Technician = nameof(UserRole.Technician);
    public const string Staff = nameof(UserRole.Staff);
    public const string TechnicianOrAdmin = nameof(UserRole.Technician) + "," + nameof(UserRole.Admin);
}

public static class UserRoles
{
    public static bool TryParse(string? value, out UserRole role) =>
        Enum.TryParse(value, ignoreCase: true, out role) && Enum.IsDefined(typeof(UserRole), role);

    public static UserRole ParseRequired(string value)
    {
        if (!TryParse(value, out var role))
            throw new ArgumentException($"Invalid role: '{value}'. Expected one of: {string.Join(", ", Enum.GetNames<UserRole>())}.", nameof(value));
        return role;
    }
}
