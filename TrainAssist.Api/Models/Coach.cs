using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TrainAssist.Api.Models;

/// <summary>
/// Represents a coach/carriage within a train
/// </summary>
public class Coach
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int TrainId { get; set; }

    [Required]
    [StringLength(10)]
    public string CoachName { get; set; } = string.Empty;

    // Navigation properties
    [ForeignKey(nameof(TrainId))]
    public virtual Train Train { get; set; } = null!;

    public virtual ICollection<CrowdReport> CrowdReports { get; set; } = new List<CrowdReport>();
}
