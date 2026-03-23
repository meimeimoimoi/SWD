using System.Data;
using System.Data.Common;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Data;

public sealed class EfMigrationHistoryChecksumService
{
    private const string HistoryTable = "__EFMigrationsHistory";

    private readonly AppDbContext _context;
    private readonly ILogger<EfMigrationHistoryChecksumService> _logger;

    public EfMigrationHistoryChecksumService(
        AppDbContext context,
        ILogger<EfMigrationHistoryChecksumService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task ValidateSealAndVerifyAsync(CancellationToken cancellationToken = default)
    {
        var connection = _context.Database.GetDbConnection();
        await OpenConnectionAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await HistoryTableExistsAsync(connection, cancellationToken).ConfigureAwait(false))
            return;

        if (!await ChecksumColumnExistsAsync(connection, cancellationToken).ConfigureAwait(false))
        {
            _logger.LogWarning(
                "{Table}.Checksum column is missing; skipping migration checksum validation until migrations are applied.",
                HistoryTable);
            return;
        }

        var migrator = _context.Database.GetService<IMigrator>();
        var knownIds = _context.Database.GetService<IMigrationsAssembly>()
            .Migrations.Keys.ToHashSet(StringComparer.Ordinal);

        var applied = await ReadAppliedRowsAsync(connection, cancellationToken).ConfigureAwait(false);
        if (applied.Count == 0)
            return;

        string? previousId = null;
        foreach (var row in applied)
        {
            cancellationToken.ThrowIfCancellationRequested();

            if (!knownIds.Contains(row.MigrationId))
            {
                throw new InvalidOperationException(
                    $"Database lists applied migration '{row.MigrationId}' but it is not in this application. " +
                    "Deploy the matching migration assembly or repair the database.");
            }

            var script = migrator.GenerateScript(previousId, row.MigrationId);
            var expected = ComputeChecksum(NormalizeScript(script));

            if (row.Checksum is null)
            {
                await UpdateChecksumAsync(connection, row.MigrationId, expected, cancellationToken)
                    .ConfigureAwait(false);
                _logger.LogInformation("Recorded checksum for applied migration {MigrationId}", row.MigrationId);
            }
            else if (!string.Equals(row.Checksum, expected, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException(
                    $"Migration checksum mismatch for '{row.MigrationId}'. " +
                    "An applied migration was changed after it ran (Flyway-style check). " +
                    $"Stored checksum: {row.Checksum}; expected from this build: {expected}. " +
                    "Do not edit migrations that are already applied; add a new migration instead.");
            }

            previousId = row.MigrationId;
        }
    }

    private static async Task OpenConnectionAsync(DbConnection connection, CancellationToken cancellationToken)
    {
        if (connection.State != ConnectionState.Open)
            await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
    }

    private static async Task<bool> HistoryTableExistsAsync(DbConnection connection, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText =
            $"SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'{HistoryTable}'";
        var o = await cmd.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        return o != null && o != DBNull.Value;
    }

    private static async Task<bool> ChecksumColumnExistsAsync(DbConnection connection, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText =
            """
            SELECT COL_LENGTH(N'dbo.__EFMigrationsHistory', N'Checksum')
            """;
        var o = await cmd.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        return o != null && o != DBNull.Value && Convert.ToInt32(o) > 0;
    }

    private static async Task<List<HistoryRow>> ReadAppliedRowsAsync(
        DbConnection connection,
        CancellationToken cancellationToken)
    {
        var list = new List<HistoryRow>();
        await using var cmd = connection.CreateCommand();
        cmd.CommandText =
            $"""
            SELECT [MigrationId], [Checksum]
            FROM [{HistoryTable}]
            ORDER BY [MigrationId]
            """;
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
        while (await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
        {
            var id = reader.GetString(0);
            string? checksum = reader.IsDBNull(1) ? null : reader.GetString(1);
            list.Add(new HistoryRow(id, checksum));
        }

        return list;
    }

    private static async Task UpdateChecksumAsync(
        DbConnection connection,
        string migrationId,
        string checksum,
        CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText =
            $"""
            UPDATE [{HistoryTable}]
            SET [Checksum] = @checksum
            WHERE [MigrationId] = @id
            """;
        var pChecksum = cmd.CreateParameter();
        pChecksum.ParameterName = "@checksum";
        pChecksum.Value = checksum;
        cmd.Parameters.Add(pChecksum);
        var pId = cmd.CreateParameter();
        pId.ParameterName = "@id";
        pId.Value = migrationId;
        cmd.Parameters.Add(pId);
        await cmd.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
    }

    private static string NormalizeScript(string script) =>
        script.Replace("\r\n", "\n", StringComparison.Ordinal).Replace('\r', '\n').TrimEnd();

    private static string ComputeChecksum(string normalizedScript)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(normalizedScript));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    private sealed record HistoryRow(string MigrationId, string? Checksum);
}
