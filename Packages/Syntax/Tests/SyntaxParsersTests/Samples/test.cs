// C# highlight / outline sample for tree-sitter-c-sharp
#nullable enable
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Json = System.Text.Json.JsonSerializer;

namespace Sample.App.Core;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public sealed class DemoAttribute : Attribute
{
    public string Name { get; }
    public DemoAttribute(string name) => Name = name;
}

public interface IRepository<T>
{
    ValueTask<T?> FindAsync(Guid id, CancellationToken cancellationToken = default);
    IAsyncEnumerable<T> StreamAllAsync(CancellationToken cancellationToken = default);
}

public readonly record struct Money(decimal Amount, string Currency)
{
    public static readonly Money Zero = new(0m, "USD");
    public static Money operator +(Money left, Money right)
        => left.Currency == right.Currency
            ? new(left.Amount + right.Amount, left.Currency)
            : throw new InvalidOperationException("Currency mismatch");

    public override string ToString() => $"{Amount:N2} {Currency}";
}

public enum Status
{
    Unknown = 0,
    Active = 1,
    Disabled = 2,
}

public sealed class User
{
    public Guid Id { get; init; }
    public required string Name { get; init; }
    public string Email { get; set; } = string.Empty;
    public Status Status { get; set; } = Status.Unknown;
    public Dictionary<string, object?> Metadata { get; } = new(StringComparer.OrdinalIgnoreCase);

    public event EventHandler<string>? Renamed;

    public void Rename(string newName)
    {
        if (string.IsNullOrWhiteSpace(newName))
        {
            throw new ArgumentException("Name is required", nameof(newName));
        }

        Name = newName.Trim();
        Renamed?.Invoke(this, Name);
    }
}

public static class UserExtensions
{
    public static bool IsReachable(this User user)
        => user is { Status: Status.Active, Email.Length: > 3 };
}

[Demo("service")]
public sealed class UserService(IRepository<User> repository)
{
    private readonly IRepository<User> _repository = repository;

    public async Task<User> RequireAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _repository.FindAsync(id, cancellationToken);
        return user ?? throw new KeyNotFoundException($"User not found: {id}");
    }

    public async IAsyncEnumerable<User> SearchAsync(
        string term,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        await foreach (var user in _repository.StreamAllAsync(cancellationToken))
        {
            if (user.Name.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                user.Email.Contains(term, StringComparison.OrdinalIgnoreCase))
            {
                yield return user;
            }
        }
    }

    public string Summarize(User user)
    {
        string Category(Status status) => status switch
        {
            Status.Active => "live",
            Status.Disabled => "blocked",
            _ => "unknown",
        };

        var flags = user.Metadata
            .Where(kv => kv.Value is bool b && b)
            .Select(kv => kv.Key)
            .OrderBy(x => x)
            .ToArray();

        var json = Json.Serialize(new
        {
            user.Id,
            user.Name,
            user.Email,
            Status = user.Status.ToString(),
            Category = Category(user.Status),
            Flags = flags,
        });

        return $"{user.Name} <{user.Email}> => {json}";
    }
}

public static class Program
{
    public static async Task<int> Main(string[] args)
    {
        var now = DateTimeOffset.UtcNow;
        var ids = new[] { Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid() };

        var (ok, message) = TryParse(args.FirstOrDefault()) switch
        {
            > 0 and < 100 => (true, "range: small"),
            >= 100 => (true, "range: big"),
            _ => (false, "invalid"),
        };

        Console.WriteLine($"[{now:O}] {message}");

        // raw string + interpolation
        var report = $$"""
        {
          "ok": {{ok.ToString().ToLowerInvariant()}},
          "ids": ["{{string.Join("\",\"", ids)}}"]
        }
        """;
        Console.WriteLine(report);

#if DEBUG
        Console.WriteLine("DEBUG build");
#else
        Console.WriteLine("RELEASE build");
#endif

        await Task.Delay(10);
        return ok ? 0 : 1;

        static int TryParse(string? value)
            => int.TryParse(value, out var number) ? number : -1;
    }
}
