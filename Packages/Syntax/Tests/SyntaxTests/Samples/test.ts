// TypeScript highlight sample for tree-sitter-typescript

import fs, { readFileSync as read, type Stats } from "node:fs";
import * as path from "node:path";
import json from "./config.json" assert { type: "json" };
export { read };
export type { Stats };

declare global {
  interface Window {
    __APP_VERSION__: string;
  }
}

type ID = string | number | bigint;
type ReadonlyRecord<K extends PropertyKey, V> = {
  readonly [P in K]?: V;
};
type ValueOf<T> = T[keyof T];

interface User {
  id: ID;
  name: string;
  email?: string;
  role: "admin" | "user" | "guest";
  tags: string[];
}

interface ApiResult<T> {
  ok: boolean;
  data: T;
  error?: Error;
}

enum LogLevel {
  Debug = 10,
  Info = 20,
  Warn = 30,
  Error = 40,
}

const enum Flag {
  None = 0,
  Read = 1 << 0,
  Write = 1 << 1,
  Execute = 1 << 2,
}

namespace Legacy {
  export const version = "1.0.0";
}

abstract class BaseRepository<T extends { id: ID }> {
  #cache = new Map<ID, T>();
  protected abstract table: string;

  constructor(protected readonly root: string) {}

  get size(): number {
    return this.#cache.size;
  }

  set seed(items: T[]) {
    for (const item of items) this.#cache.set(item.id, item);
  }

  async findById(id: ID): Promise<T | undefined> {
    return this.#cache.get(id);
  }

  protected save(item: T): void {
    this.#cache.set(item.id, item);
  }
}

class UserRepository extends BaseRepository<User> {
  protected table = "users";
  static readonly defaultRole = "guest" as const;

  override async findById(id: ID): Promise<User | undefined> {
    const user = await super.findById(id);
    return user?.role === "guest" ? { ...user, tags: [...user.tags, "new"] } : user;
  }
}

function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${String(x)}`);
}

function log(level: LogLevel, message: string): void {
  switch (level) {
    case LogLevel.Debug:
    case LogLevel.Info:
    case LogLevel.Warn:
    case LogLevel.Error:
      console.log(`[${LogLevel[level]}] ${message}`);
      break;
    default:
      assertNever(level);
  }
}

const fallbackUser = {
  id: 0n,
  name: "anonymous",
  role: "guest",
  tags: [],
} satisfies User;

const tuple = [1, "two", true] as const;
const [first, second, ...rest] = tuple;
const [, maybeThird = false] = [undefined, undefined, ...rest];

const permissions = Flag.Read | Flag.Write;
const hasWrite = (permissions & Flag.Write) !== 0;

function parseInput(input: unknown): User | null {
  if (
    typeof input === "object" &&
    input !== null &&
    "id" in input &&
    "name" in input &&
    "role" in input &&
    "tags" in input
  ) {
    return input as User;
  }
  return null;
}

async function* lines(filePath: string): AsyncGenerator<string, void, unknown> {
  const content = await fs.promises.readFile(filePath, "utf8");
  for (const line of content.split(/\r?\n/u)) {
    yield line;
  }
}

const replacer: (this: unknown, key: string, value: unknown) => unknown = function (
  key,
  value,
) {
  if (typeof value === "bigint") return `${value}n`;
  return key.startsWith("_") ? undefined : value;
};

const asyncTask = async <T>(value: T): Promise<T> => value;
const identity = <T,>(value: T): T => value;

@sealed
class Service {
  accessor state = { ready: false };

  constructor(public readonly name: string) {}

  @logCall("run")
  run(...args: unknown[]): string {
    return `${this.name}:${args.join(",")}`;
  }
}

function sealed<T extends new (...args: any[]) => object>(ctor: T): T {
  Object.seal(ctor);
  Object.seal(ctor.prototype);
  return ctor;
}

function logCall(_label: string) {
  return function (
    _target: object,
    _propertyKey: string | symbol,
    descriptor: PropertyDescriptor,
  ) {
    const original = descriptor.value as (...args: unknown[]) => unknown;
    descriptor.value = function (...args: unknown[]) {
      console.debug("called", args);
      return original.apply(this, args);
    };
  };
}

const regex = /^(?<name>[a-z_]\w*)(\((?<args>.*)\))?$/giu;
const str = `template: ${identity(second)} / ${String.raw`\nraw`}`;
const ch = "\u{1F600}";

async function main(): Promise<void> {
  const repo = new UserRepository(path.resolve(process.cwd(), "data"));
  repo.seed = [fallbackUser];

  const user = (await repo.findById(first)) ?? fallbackUser;
  const normalized = {
    ...user,
    email: user.email ?? "n/a",
    tags: user.tags.map((t) => t.toUpperCase()),
  };

  for await (const line of lines(path.join(repo.root, "users.txt"))) {
    if (!line.trim()) continue;
    console.log(line);
  }

  const payload: ApiResult<User> = { ok: true, data: normalized };
  const maybeJson = JSON.stringify(payload, replacer, 2);
  const config = json?.features?.typescript ?? {};
  const len = readFileSyncLength("README.md");

  log(LogLevel.Info, `write=${hasWrite}, len=${len}, ch=${ch}, cfg=${String(config)}`);
  console.log(regex.test(str), maybeThird, maybeJson);
}

function readFileSyncLength(file: string): number {
  try {
    const data = read(file, "utf8");
    return data.length;
  } catch (error) {
    if (error instanceof Error) {
      console.error(error.message);
    } else {
      console.error("unknown error");
    }
    return -1;
  } finally {
    // no-op
  }
}

void main();

export default Service;
export { type ApiResult, type User, LogLevel, Legacy };
