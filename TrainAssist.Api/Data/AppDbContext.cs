using Microsoft.EntityFrameworkCore;
using TrainAssist.Api.Models;

namespace TrainAssist.Api.Data;

/// <summary>
/// Database context for the Train Assist application
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    // DbSet properties
    public DbSet<User> Users { get; set; }
    public DbSet<Train> Trains { get; set; }
    public DbSet<Coach> Coaches { get; set; }
    public DbSet<CrowdReport> CrowdReports { get; set; }
    public DbSet<SOSReport> SOSReports { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure User entity
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(20);
        });

        // Configure Train entity
        modelBuilder.Entity<Train>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.TrainName).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Source).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Destination).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Timing).IsRequired().HasMaxLength(10);
            entity.Property(e => e.Platform).HasMaxLength(10);

            // Configure one-to-many relationship with Coach
            entity.HasMany(e => e.Coaches)
                  .WithOne(e => e.Train)
                  .HasForeignKey(e => e.TrainId)
                  .OnDelete(DeleteBehavior.Cascade);

            // Add indexes for search performance
            entity.HasIndex(e => e.Source);
            entity.HasIndex(e => e.Destination);
        });

        // Configure Coach entity
        modelBuilder.Entity<Coach>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.CoachName).IsRequired().HasMaxLength(10);
            entity.Property(e => e.TrainId).IsRequired();

            // Configure one-to-many relationship with CrowdReport
            entity.HasMany(e => e.CrowdReports)
                  .WithOne(e => e.Coach)
                  .HasForeignKey(e => e.CoachId)
                  .OnDelete(DeleteBehavior.Cascade);

            // Add index on TrainId for query performance
            entity.HasIndex(e => e.TrainId);
        });

        // Configure CrowdReport entity
        modelBuilder.Entity<CrowdReport>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ReporterName).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Status).IsRequired().HasMaxLength(20);
            entity.Property(e => e.Timestamp).IsRequired();
            entity.Property(e => e.CoachId).IsRequired();

            // Add indexes for query performance
            entity.HasIndex(e => e.CoachId);
            entity.HasIndex(e => e.Timestamp);
        });

        // Configure SOSReport entity
        modelBuilder.Entity<SOSReport>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ReporterName).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Message).HasMaxLength(500);
            entity.Property(e => e.Timestamp).IsRequired();

            // Configure optional relationships
            entity.HasOne(e => e.Train)
                  .WithMany()
                  .HasForeignKey(e => e.TrainId)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(e => e.Coach)
                  .WithMany()
                  .HasForeignKey(e => e.CoachId)
                  .OnDelete(DeleteBehavior.SetNull);

            // Add indexes for query performance
            entity.HasIndex(e => e.TrainId);
            entity.HasIndex(e => e.CoachId);
            entity.HasIndex(e => e.Timestamp);
        });
    }
}
