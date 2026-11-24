#!/usr/bin/env node

/**
 * Mock OTLP HTTP Collector Server
 * Listens on http://127.0.0.1:4318 and logs received OpenTelemetry trace spans.
 */

const http = require("http");

const PORT = process.env.PORT || 4318;
const HOST = process.env.HOST || "127.0.0.1";

const server = http.createServer((req, res) => {
  let body = "";

  req.on("data", (chunk) => {
    body += chunk;
  });

  req.on("end", () => {
    const timestamp = new Date().toISOString();
    console.log(
      `[MOCK_COLLECTOR] ${timestamp} ${req.method} ${req.url} - ${body.length} bytes received`,
    );

    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({}));
  });
});

server.listen(PORT, HOST, () => {
  console.log(`[MOCK_COLLECTOR] Ready and listening on http://${HOST}:${PORT}`);
  console.log(
    `[MOCK_COLLECTOR] Waiting for OpenTelemetry traces (POST /v1/traces)...`,
  );
});
