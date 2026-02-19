using TrainAssist.Api.Models;

namespace TrainAssist.Api.Data;

/// <summary>
/// Seeds initial data into the database for development and testing
/// </summary>
public static class DataSeeder
{
    public static void SeedData(AppDbContext context)
    {
        // Check if data already exists
        if (context.Trains.Any())
        {
            Console.WriteLine("Database already seeded. Skipping seed data.");
            return;
        }

        Console.WriteLine("Seeding database with initial data...");

        var random = new Random();

        // Create 3 trains
        var trains = new List<Train>
        {
            new Train
            {
                TrainName = "Express 101",
                Source = "CityA",
                Destination = "CityB",
                Timing = "07:30",
                Platform = "3"
            },
            new Train
            {
                TrainName = "InterCity 202",
                Source = "CityA",
                Destination = "CityC",
                Timing = "09:15",
                Platform = "1"
            },
            new Train
            {
                TrainName = "Local 303",
                Source = "CityB",
                Destination = "CityD",
                Timing = "12:00",
                Platform = "2"
            }
        };

        context.Trains.AddRange(trains);
        context.SaveChanges();

        Console.WriteLine($"✅ Seeded {trains.Count} trains");

        // Create 3 coaches for each train (S1, S2, S3)
        var coaches = new List<Coach>();
        var statuses = new[] { "Low", "Medium", "High" };

        foreach (var train in trains)
        {
            for (int i = 1; i <= 3; i++)
            {
                var coach = new Coach
                {
                    TrainId = train.Id,
                    CoachName = $"S{i}"
                };
                coaches.Add(coach);
            }
        }

        context.Coaches.AddRange(coaches);
        context.SaveChanges();

        Console.WriteLine($"✅ Seeded {coaches.Count} coaches");

        // Create initial crowd reports for each coach
        var crowdReports = new List<CrowdReport>();
        int statusIndex = 0;

        foreach (var coach in coaches)
        {
            var report = new CrowdReport
            {
                CoachId = coach.Id,
                ReporterName = "System",
                Status = statuses[statusIndex % statuses.Length],
                Timestamp = DateTime.UtcNow.AddHours(-random.Next(1, 6)) // 1-5 hours ago
            };
            crowdReports.Add(report);
            statusIndex++;
        }

        context.CrowdReports.AddRange(crowdReports);
        context.SaveChanges();

        Console.WriteLine($"✅ Seeded {crowdReports.Count} initial crowd reports");

        Console.WriteLine("🎉 Database seeding completed successfully!");
        Console.WriteLine();
        Console.WriteLine("Seeded Data Summary:");
        Console.WriteLine($"  - Trains: {trains.Count}");
        Console.WriteLine($"  - Coaches: {coaches.Count}");
        Console.WriteLine($"  - Crowd Reports: {crowdReports.Count}");
        Console.WriteLine();
    }
}
