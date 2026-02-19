using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TrainAssist.Api.Models;

/// <summary>
/// Represents a crowd status report for a specific coach
/// </summary>
public class CrowdReport
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int CoachId { get; set; }

    [Required]
    [StringLength(100)]
    public string ReporterName { get; set; } = string.Empty;

    [Required]
    [StringLength(20)]
    public string Status { get; set; } = string.Empty; // "Low", "Medium", "High"

    [Required]
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // Navigation property
    [ForeignKey(nameof(CoachId))]
    public virtual Coach Coach { get; set; } = null!;
}
