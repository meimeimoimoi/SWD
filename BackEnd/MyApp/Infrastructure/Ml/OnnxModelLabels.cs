using System.Text.Json;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;

namespace MyApp.Infrastructure.Ml;

/// <summary>Reads <c>class_labels</c> from ONNX metadata (JSON string array). Must match output size.</summary>
internal static class OnnxModelLabels
{
    public static string[] Read(InferenceSession session)
    {
        if (!session.ModelMetadata.CustomMetadataMap.TryGetValue("class_labels", out var json) ||
            string.IsNullOrWhiteSpace(json))
        {
            throw new InvalidOperationException(
                "ONNX model needs metadata key 'class_labels' with a JSON array of class names (output order).");
        }

        var labels = JsonSerializer.Deserialize<string[]>(json);
        if (labels is not { Length: > 0 })
            throw new InvalidOperationException("ONNX metadata 'class_labels' must be a non-empty JSON string array.");

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
