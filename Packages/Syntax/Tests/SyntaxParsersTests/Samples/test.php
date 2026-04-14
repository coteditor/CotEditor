<?php
declare(strict_types=1);

namespace App\Domain;

use App\Contracts\Identifiable;
use InvalidArgumentException;

// --- Constants & Enums ---

const VERSION = '2.0.0';

enum Status: string
{
    case Active = 'active';
    case Inactive = 'inactive';
    case Pending = 'pending';

    public function label(): string
    {
        return match ($this) {
            self::Active => 'Active',
            self::Inactive => 'Inactive',
            self::Pending => 'Pending',
        };
    }
}

// --- Interfaces & Traits ---

interface Identifiable
{
    public function id(): int;
}

interface Displayable
{
    public function display(): string;
}

#[Attribute(Attribute::TARGET_CLASS)]
class Deprecated
{
    public function __construct(
        public readonly string $reason = '',
    ) {}
}

trait HasTimestamps
{
    private ?string $createdAt = null;
    private ?string $updatedAt = null;

    public function touch(): void
    {
        $this->updatedAt = date('c');
    }

    public function getCreatedAt(): ?string
    {
        return $this->createdAt;
    }
}

// --- Classes ---

abstract class Entity implements Identifiable
{
    abstract public function validate(): bool;

    public function __toString(): string
    {
        return static::class . '#' . $this->id();
    }
}

#[Deprecated(reason: 'Use UserV2 instead')]
final class User extends Entity implements Displayable
{
    use HasTimestamps;

    private static int $instanceCount = 0;

    public function __construct(
        private readonly int $id,
        private string $name,
        private string $email,
        private Status $status = Status::Active,
    ) {
        self::$instanceCount++;
        $this->createdAt = date('c');
    }

    public function id(): int
    {
        return $this->id;
    }

    public function validate(): bool
    {
        return str_contains($this->email, '@')
            && strlen($this->name) >= 2;
    }

    public function display(): string
    {
        return sprintf('%s <%s> [%s]', $this->name, $this->email, $this->status->label());
    }

    public static function count(): int
    {
        return self::$instanceCount;
    }
}

// --- Generics-like Collection ---

class Collection
{
    /** @var array<int, mixed> */
    private array $items;

    public function __construct(mixed ...$items)
    {
        $this->items = array_values($items);
    }

    public function map(callable $fn): self
    {
        return new self(...array_map($fn, $this->items));
    }

    public function filter(callable $fn): self
    {
        return new self(...array_values(array_filter($this->items, $fn)));
    }

    public function first(): mixed
    {
        return $this->items[0] ?? null;
    }

    public function toArray(): array
    {
        return $this->items;
    }
}

// --- Functions ---

function createUser(int $id, string $name, string $email): User
{
    if ($id <= 0) {
        throw new InvalidArgumentException("ID must be positive, got {$id}");
    }

    return new User(id: $id, name: $name, email: $email);
}

/**
 * Processes users and returns a summary report.
 *
 * @param  User[]  $users
 * @return array{total: int, active: int, display: string[]}
 */
function summarize(array $users): array
{
    $active = array_filter($users, fn(User $u) => $u->validate());

    return [
        'total' => count($users),
        'active' => count($active),
        'display' => array_map(fn(User $u) => $u->display(), $active),
    ];
}

// --- Pattern Matching & Control Flow ---

function classify(mixed $value): string
{
    return match (true) {
        is_int($value) && $value > 0 => 'positive integer',
        is_int($value) => 'non-positive integer',
        is_string($value) => "string({$value})",
        is_array($value) => 'array[' . count($value) . ']',
        $value instanceof Displayable => $value->display(),
        $value === null => 'null',
        default => 'unknown',
    };
}

// --- String Literals & Heredoc ---

$heredoc = <<<HTML
    <div class="card">
        <h2>{$user->display()}</h2>
        <span>Status: active</span>
    </div>
    HTML;

$nowdoc = <<<'SQL'
    SELECT u.id, u.name
    FROM users AS u
    WHERE u.status = 'active'
    ORDER BY u.created_at DESC
    SQL;

// --- Regular Expressions ---

$pattern = '/^(?P<name>[A-Z][a-z]+)\s+(?P<age>\d{1,3})$/u';
$input = 'Alice 30';

if (preg_match($pattern, $input, $matches)) {
    printf("Name: %s, Age: %d\n", $matches['name'], (int)$matches['age']);
}

// --- Main ---

try {
    $alice = createUser(1, 'Alice', 'alice@example.com');
    $bob = createUser(2, 'Bob', 'bob@example.com');

    $collection = new Collection($alice, $bob);
    $valid = $collection->filter(fn(User $u) => $u->validate());

    $report = summarize($valid->toArray());
    echo "Total: {$report['total']}, Active: {$report['active']}\n";

    foreach ($report['display'] as $line) {
        echo "  - {$line}\n";
    }

    echo classify(42) . PHP_EOL;
    echo classify('hello') . PHP_EOL;
    echo classify($alice) . PHP_EOL;
} catch (InvalidArgumentException $e) {
    fprintf(STDERR, "Validation error: %s\n", $e->getMessage());
} catch (\Throwable $e) {
    fprintf(STDERR, "Unexpected error: %s\n", $e->getMessage());
    exit(1);
}
