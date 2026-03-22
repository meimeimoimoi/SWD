using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using MyApp.Application.Features.Treatment.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services;

public sealed class AiSolutionSuggestionService : IAiSolutionSuggestionService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly AppDbContext _context;
    private readonly ITreatmentService _treatmentService;
    private readonly ILogger<AiSolutionSuggestionService> _logger;

    public AiSolutionSuggestionService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        AppDbContext context,
        ITreatmentService treatmentService,
        ILogger<AiSolutionSuggestionService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _context = context;
        _treatmentService = treatmentService;
        _logger = logger;
    }

    public async Task<AiSolutionSuggestResponse> SuggestAsync(
        AiSolutionSuggestRequest request,
        CancellationToken cancellationToken = default)
    {
        var diseaseLabel = (request.DiseaseName ?? string.Empty).Trim();
        TreeIllness? illness = null;

        if (request.IllnessId is int id && id > 0)
        {
            illness = await _context.TreeIllnesses.AsNoTracking()
                .FirstOrDefaultAsync(i => i.IllnessId == id, cancellationToken);
            if (illness != null && string.IsNullOrEmpty(diseaseLabel))
                diseaseLabel = illness.IllnessName ?? $"Illness #{id}";
        }

        if (illness == null && !string.IsNullOrEmpty(diseaseLabel))
        {
            illness = await _context.TreeIllnesses.AsNoTracking()
                .FirstOrDefaultAsync(
                    i => i.IllnessName != null && i.IllnessName == diseaseLabel,
                    cancellationToken);
        }

        var resolvedIllnessId = illness?.IllnessId ?? request.IllnessId;
        List<TreatmentRecommendationDto> catalog = new();
        if (resolvedIllnessId is int rid && rid > 0)
            catalog = await _treatmentService.GetRecommendationsByIllnessAsync(rid);

        var apiKey = _configuration["AiSolution:OpenAiApiKey"]?.Trim();
        if (!string.IsNullOrEmpty(apiKey))
        {
            try
            {
                var fromLlm = await TryOpenAiAsync(
                    apiKey,
                    illness,
                    catalog,
                    diseaseLabel,
                    request.Confidence,
                    cancellationToken);
                if (fromLlm != null)
                    return fromLlm;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "OpenAI solution suggestion failed; using heuristic fallback.");
            }
        }

        return BuildHeuristic(illness, catalog, diseaseLabel, request.Confidence);
    }

    private static AiSolutionSuggestResponse BuildHeuristic(
        TreeIllness? illness,
        List<TreatmentRecommendationDto> catalog,
        string diseaseLabel,
        double? confidence)
    {
        var label = string.IsNullOrEmpty(diseaseLabel) ? "this condition" : diseaseLabel;
        var steps = new List<string>();
        foreach (var s in catalog.OrderBy(x => x.Priority ?? 999))
        {
            var name = (s.SolutionName ?? "Step").Trim();
            var desc = (s.Description ?? string.Empty).Trim();
            var type = (s.SolutionType ?? string.Empty).Trim();
            var line = string.IsNullOrEmpty(desc)
                ? $"[{type}] {name}"
                : $"[{type}] {name}: {desc}";
            steps.Add(line);
        }

        if (steps.Count == 0)
        {
            steps.Add(
                "No treatment rows are stored in the catalog for this disease yet. Consult your local extension service or agronomist for field-specific IPM.");
        }

        var confText = confidence is > 0
            ? $"The vision model reported about {confidence:P0} confidence for «{label}». "
            : string.Empty;

        var overview = illness?.Symptoms ?? illness?.Description;
        var summary = confText;
        if (!string.IsNullOrWhiteSpace(overview))
            summary += $"Disease notes from the master record: {overview} ";
        else
            summary +=
                "Use the catalog steps below as a starting point; verify symptoms in the field before applying crop protection products. ";

        return new AiSolutionSuggestResponse
        {
            Source = "heuristic",
            Summary = summary.Trim(),
            ActionSteps = steps,
            Disclaimer =
                "Informational only. Always follow registered pesticide labels and national or local regulations. Not a substitute for professional agronomic advice.",
        };
    }

    private async Task<AiSolutionSuggestResponse?> TryOpenAiAsync(
        string apiKey,
        TreeIllness? illness,
        List<TreatmentRecommendationDto> catalog,
        string diseaseLabel,
        double? confidence,
        CancellationToken cancellationToken)
    {
        var model = _configuration["AiSolution:OpenAiModel"]?.Trim();
        if (string.IsNullOrEmpty(model))
            model = "gpt-4o-mini";

        var baseUrl = _configuration["AiSolution:OpenAiBaseUrl"]?.Trim();
        if (string.IsNullOrEmpty(baseUrl))
            baseUrl = "https://api.openai.com/v1/";

        var sb = new StringBuilder();
        sb.AppendLine("Disease label: ").AppendLine(diseaseLabel);
        if (confidence is > 0)
            sb.AppendLine($"Classifier confidence: {confidence:P2}");
        if (illness != null)
        {
            sb.AppendLine("DB illness name: ").AppendLine(illness.IllnessName ?? "");
            if (!string.IsNullOrWhiteSpace(illness.ScientificName))
                sb.AppendLine("Scientific: ").AppendLine(illness.ScientificName);
            if (!string.IsNullOrWhiteSpace(illness.Symptoms))
                sb.AppendLine("Symptoms: ").AppendLine(illness.Symptoms);
            if (!string.IsNullOrWhiteSpace(illness.Causes))
                sb.AppendLine("Causes: ").AppendLine(illness.Causes);
        }

        sb.AppendLine("Catalog treatment rows:");
        foreach (var s in catalog.OrderBy(x => x.Priority ?? 999))
        {
            sb.Append("- ").Append(s.SolutionType ?? "").Append(' ').Append(s.SolutionName ?? "").Append(": ")
                .AppendLine(s.Description ?? "");
        }

        var userPrompt =
            "You are a rice crop protection assistant. Using the facts below, respond with a single JSON object ONLY (no markdown) with keys: " +
            "\"summary\" (string, 2-4 sentences), \"actionSteps\" (array of 3-8 short actionable strings for farmers), " +
            "\"disclaimer\" (one sentence). " +
            "Do not invent specific product trade names unless they appear in the catalog. Prefer IPM language.\n\n" +
            sb;

        var payload = new
        {
            model,
            temperature = 0.35,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new { role = "system", content = "Output valid JSON only." },
                new { role = "user", content = userPrompt },
            },
        };

        var client = _httpClientFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        client.Timeout = TimeSpan.FromSeconds(60);

        var url = baseUrl.EndsWith('/') ? baseUrl + "chat/completions" : baseUrl + "/chat/completions";
        using var content = new StringContent(
            JsonSerializer.Serialize(payload),
            Encoding.UTF8,
            "application/json");

        using var resp = await client.PostAsync(url, content, cancellationToken);
        var body = await resp.Content.ReadAsStringAsync(cancellationToken);
        if (!resp.IsSuccessStatusCode)
        {
            _logger.LogWarning("OpenAI HTTP {Status}: {Body}", (int)resp.StatusCode, body);
            return null;
        }

        using var doc = JsonDocument.Parse(body);
        var text = doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content")
            .GetString();
        if (string.IsNullOrWhiteSpace(text))
            return null;

        var parsed = JsonSerializer.Deserialize<LlmJson>(text, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
        });
        if (parsed == null || string.IsNullOrWhiteSpace(parsed.Summary))
            return null;

        return new AiSolutionSuggestResponse
        {
            Source = "openai",
            Summary = parsed.Summary.Trim(),
            ActionSteps = parsed.ActionSteps ?? new List<string>(),
            Disclaimer = string.IsNullOrWhiteSpace(parsed.Disclaimer)
                ? BuildHeuristic(illness, catalog, diseaseLabel, confidence).Disclaimer
                : parsed.Disclaimer.Trim(),
        };
    }

    private sealed class LlmJson
    {
        [JsonPropertyName("summary")]
        public string? Summary { get; set; }

        [JsonPropertyName("actionSteps")]
        public List<string>? ActionSteps { get; set; }

        [JsonPropertyName("disclaimer")]
        public string? Disclaimer { get; set; }
    }
}
