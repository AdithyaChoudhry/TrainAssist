namespace TrainAssist.Api.DTOs;

/// <summary>
/// Response DTO for Crowd Report
/// </summary>
public class CrowdReportResponseDto
{
    public int Id { get; set; }
    public int CoachId { get; set; }
    public string ReporterName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
}
