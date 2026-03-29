<?php
declare(strict_types=1);

final class User
{
    public function __construct(
        public int $id,
        public string $name,
    ) {}

    public function label(string $prefix = 'user'): string
    {
        return sprintf('%s:%d:%s', $prefix, $this->id, $this->name);
    }
}

function total(array $values): int
{
    $sum = 0;
    foreach ($values as $value) {
        $sum += (int)$value;
    }
    return $sum;
}

$user = new User(1, 'Alice');
echo $user->label() . PHP_EOL;
echo total([1, 2, 3]) . PHP_EOL;
