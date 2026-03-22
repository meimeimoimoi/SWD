using System.Text.Json;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;

namespace MyApp.Infrastructure.Ml;

internal static class OnnxModelLabels
{
    public static string[] Read(InferenceSession session, string? onnxModelPath = null)
    {
        string? json = null;
        if (session.ModelMetadata.CustomMetadataMap.TryGetValue("class_labels", out var meta) &&
            !string.IsNullOrWhiteSpace(meta))
        {
            json = meta;
        }
        else if (!string.IsNullOrWhiteSpace(onnxModelPath))
        {
            var sidecar = Path.ChangeExtension(onnxModelPath, ".class_labels.json");
            if (File.Exists(sidecar))
                json = File.ReadAllText(sidecar);
        }

        if (string.IsNullOrWhiteSpace(json))
        {
            throw new InvalidOperationException(
                "ONNX model needs custom metadata key 'class_labels' (JSON array of names) " +
                "or a sidecar file next to the .onnx: same base name + '.class_labels.json'.");
        }

        var labels = JsonSerializer.Deserialize<string[]>(json);
        if (labels is not { Length: > 0 })
            throw new InvalidOperationException("class_labels must be a non-empty JSON string array.");

        var n = ProbeOutputLength(session);
        if (labels.Length != n)
            throw new InvalidOperationException($"class_labels has {labels.Length} entries but model output size is {n}.");

        return labels;
    }

    private static int ProbeOutputLength(InferenceSession session)
    {
        var outName = session.OutputMetadata.Keys.First();
        var inName = session.InputMetadata.Keys.First();
        var d = session.InputMetadata[inName].Dimensions;
        DenseTensor<float> t = d[1] == 3
            ? new DenseTensor<float>(new[] { 1, 3, 224, 224 })
            : new DenseTensor<float>(new[] { 1, 224, 224, 3 });

        using var r = session.Run(new List<NamedOnnxValue> { NamedOnnxValue.CreateFromTensor(inName, t) });
        return r.First(x => x.Name == outName).AsEnumerable<float>().ToArray().Length;
    }
}
