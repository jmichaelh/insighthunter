type Level = "debug" | "info" | "warn" | "error";

interface LogEntry {
  level:   Level;
  message: string;
  ts:      string;
  data?:   unknown;
}

function log(level: Level, message: string, data?: unknown): void {
  const entry: LogEntry = { level, message, ts: new Date().toISOString(), data };
  const line = JSON.stringify(entry);
  if (level === "error" || level === "warn") {
    console.error(line);
  } else {
    console.log(line);
  }
}

export const logger = {
  debug: (msg: string, data?: unknown) => log("debug", msg, data),
  info:  (msg: string, data?: unknown) => log("info",  msg, data),
  warn:  (msg: string, data?: unknown) => log("warn",  msg, data),
  error: (msg: string, data?: unknown) => log("error", msg, data),
};
