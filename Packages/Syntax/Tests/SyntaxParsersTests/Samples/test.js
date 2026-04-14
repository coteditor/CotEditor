'use strict';

// --- Constants & Symbols ---

const VERSION = '2.0.0';
const TAG = Symbol('tag');
const PI = 3.14159;

// --- Classes ---

class AppError extends Error {
  #code;

  constructor(message, code = 0) {
    super(message);
    this.name = 'AppError';
    this.#code = code;
  }

  get code() {
    return this.#code;
  }

  toJSON() {
    return { name: this.name, message: this.message, code: this.#code };
  }
}

class User {
  static #instanceCount = 0;

  #id;
  #name;
  #email;
  #status;

  constructor(id, name, email, status = 'active') {
    this.#id = id;
    this.#name = name;
    this.#email = email;
    this.#status = status;
    User.#instanceCount++;
  }

  get id() { return this.#id; }
  get name() { return this.#name; }
  get status() { return this.#status; }

  set status(value) {
    if (!['active', 'inactive', 'pending'].includes(value)) {
      throw new AppError(`Invalid status: ${value}`, 400);
    }
    this.#status = value;
  }

  display() {
    return `${this.#name} <${this.#email}> [${this.#status}]`;
  }

  validate() {
    return this.#email.includes('@') && this.#name.length >= 2;
  }

  static count() {
    return User.#instanceCount;
  }

  [TAG]() {
    return `User#${this.#id}`;
  }
}

// --- Iterables & Generators ---

class Collection {
  #items;

  constructor(...items) {
    this.#items = items;
  }

  *[Symbol.iterator]() {
    yield* this.#items;
  }

  map(fn) {
    return new Collection(...this.#items.map(fn));
  }

  filter(fn) {
    return new Collection(...this.#items.filter(fn));
  }

  first() {
    return this.#items[0] ?? null;
  }

  toArray() {
    return [...this.#items];
  }
}

function* range(start, end, step = 1) {
  for (let i = start; i < end; i += step) {
    yield i;
  }
}

async function* fetchPages(baseURL, maxPages = 5) {
  for (let page = 1; page <= maxPages; page++) {
    const res = await fetch(`${baseURL}?page=${page}`);
    if (!res.ok) break;
    yield await res.json();
  }
}

// --- Functions ---

function createUser(id, name, email) {
  if (id <= 0) {
    throw new AppError(`ID must be positive, got ${id}`, 422);
  }
  return new User(id, name, email);
}

const summarize = (users) => {
  const valid = users.filter((u) => u.validate());
  return {
    total: users.length,
    active: valid.length,
    display: valid.map((u) => u.display()),
  };
};

function classify(value) {
  switch (typeof value) {
    case 'number':
      return value > 0 ? `positive(${value})` : `non-positive(${value})`;
    case 'string':
      return value.length === 0 ? 'empty string' : `string(${value})`;
    case 'object':
      if (value === null) return 'null';
      if (Array.isArray(value)) return `array[${value.length}]`;
      if (value instanceof User) return `user(${value.name})`;
      return 'object';
    default:
      return 'unknown';
  }
}

// --- Destructuring & Spread ---

function formatEntry({ name, email, ...rest }) {
  const tags = Object.entries(rest)
    .map(([k, v]) => `${k}=${v}`)
    .join(', ');
  return `${name} <${email}>${tags ? ` (${tags})` : ''}`;
}

// --- Proxy & Reflect ---

function createReadonly(target) {
  return new Proxy(target, {
    set(_target, prop, _value) {
      throw new AppError(`Cannot set property '${String(prop)}': read-only`, 403);
    },
    deleteProperty(_target, prop) {
      throw new AppError(`Cannot delete property '${String(prop)}': read-only`, 403);
    },
  });
}

// --- Promises & Async ---

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function processUsers(users) {
  const results = await Promise.allSettled(
    users.map(async (user) => {
      await delay(10);
      if (!user.validate()) {
        throw new AppError(`Invalid user: ${user.name}`, 422);
      }
      return user.display();
    })
  );

  const fulfilled = results
    .filter((r) => r.status === 'fulfilled')
    .map((r) => r.value);
  const rejected = results
    .filter((r) => r.status === 'rejected')
    .map((r) => r.reason.message);

  return { fulfilled, rejected };
}

// --- Regular Expressions ---

const PATTERN = /^(?<name>[A-Z][a-z]+)\s+(?<age>\d{1,3})$/u;

function parseRecord(input) {
  const match = PATTERN.exec(input);
  if (!match?.groups) return null;

  const { name, age } = match.groups;
  return { name, age: parseInt(age, 10) };
}

// --- WeakMap & Metadata ---

const metadata = new WeakMap();

function annotate(obj, key, value) {
  const meta = metadata.get(obj) ?? {};
  meta[key] = value;
  metadata.set(obj, meta);
}

// --- Main ---

try {
  const alice = createUser(1, 'Alice', 'alice@example.com');
  const bob = createUser(2, 'Bob', 'bob@example.com');
  const charlie = createUser(3, 'Charlie', 'charlie@example.com');

  const users = new Collection(alice, bob, charlie);
  const valid = users.filter((u) => u.validate());

  const report = summarize(valid.toArray());
  console.log(`Total: ${report.total}, Active: ${report.active}`);

  for (const line of report.display) {
    console.log(`  - ${line}`);
  }

  const nums = [...range(0, 5)];
  console.log(`Range: ${nums.join(', ')}`);

  const record = parseRecord('Alice 30');
  console.log(`Parsed: name=${record?.name}, age=${record?.age}`);

  annotate(alice, 'role', 'admin');
  console.log(classify(42));
  console.log(classify(''));
  console.log(classify(alice));

  const frozen = createReadonly({ x: 1, y: 2 });
  console.log(`Frozen: ${JSON.stringify(frozen)}`);
  console.log(`Users created: ${User.count()}`);
} catch (e) {
  if (e instanceof AppError) {
    console.error(`AppError [${e.code}]: ${e.message}`);
  } else {
    console.error(`Unexpected: ${e.message}`);
    process.exit(1);
  }
}
