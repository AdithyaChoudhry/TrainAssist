namespace TrainAssist.Api.DTOs;

/// <summary>
/// Response DTO for SOS Report
/// </summary>
public class SOSReportResponseDto
{
    public int Id { get; set; }
    public string ReporterName { get; set; } = string.Empty;
    public int? TrainId { get; set; }
    public int? CoachId { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? Message { get; set; }
    public DateTime Timestamp { get; set; }
}
