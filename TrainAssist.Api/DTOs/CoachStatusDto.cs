namespace TrainAssist.Api.DTOs;

/// <summary>
/// Response DTO for Coach status including latest crowd report
/// </summary>
public class CoachStatusDto
{
    public int CoachId { get; set; }
    public string CoachName { get; set; } = string.Empty;
    public string LatestStatus { get; set; } = string.Empty;
    public DateTime? LastReportedAt { get; set; }
    public string? LastReporterName { get; set; }
}
