export async function cacheGet<T>(kv: KVNamespace, key: string): Promise<T | null> {
  const raw = await kv.get(key);
  return raw ? (JSON.parse(raw) as T) : null;
}

export async function cacheSet<T>(
  kv: KVNamespace,
  key: string,
  value: T,
  ttlSeconds = 300
): Promise<void> {
  await kv.put(key, JSON.stringify(value), { expirationTtl: ttlSeconds });
}

export async function cacheDel(kv: KVNamespace, key: string): Promise<void> {
  await kv.delete(key);
}

export async function cacheGetOrSet<T>(
  kv: KVNamespace,
  key: string,
  fetcher: () => Promise<T>,
  ttlSeconds = 300
): Promise<T> {
  const cached = await cacheGet<T>(kv, key);
  if (cached !== null) return cached;
  const fresh = await fetcher();
  await cacheSet(kv, key, fresh, ttlSeconds);
  return fresh;
}
