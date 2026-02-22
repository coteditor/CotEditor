'use strict';

const PI = 3.14159;

class User {
  constructor(id, name) {
    this.id = id;
    this.name = name;
  }

  label(prefix = 'user') {
    return `${prefix}:${this.id}:${this.name}`;
  }
}

function score(users) {
  return users
    .filter((u) => u.id > 0)
    .map((u) => ({ ...u, value: Math.round(u.id * PI) }));
}

const items = score([new User(1, 'Alice'), new User(2, 'Bob')]);
console.log(items[0]?.value ?? 0);
