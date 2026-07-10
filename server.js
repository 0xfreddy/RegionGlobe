const http = require("http");
const fs = require("fs");
const path = require("path");

const port = Number(process.env.PORT || 3000);
const docsRoot = path.join(__dirname, "docs");
const docsRootWithSeparator = `${docsRoot}${path.sep}`;

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon"
};

function send(response, status, body, contentType = "text/plain; charset=utf-8") {
  response.writeHead(status, {
    "Content-Type": contentType,
    "Cache-Control": status === 200 ? "public, max-age=300" : "no-store"
  });
  response.end(body);
}

function resolveRequestPath(requestUrl) {
  const url = new URL(requestUrl, `http://127.0.0.1:${port}`);
  const pathname = decodeURIComponent(url.pathname);
  const relativePath = pathname === "/" ? "index.html" : pathname.replace(/^\/+/, "");
  const filePath = path.normalize(path.join(docsRoot, relativePath));

  if (filePath !== docsRoot && !filePath.startsWith(docsRootWithSeparator)) {
    return null;
  }

  return filePath;
}

const server = http.createServer((request, response) => {
  const filePath = resolveRequestPath(request.url);

  if (!filePath) {
    send(response, 403, "Forbidden");
    return;
  }

  fs.readFile(filePath, (error, data) => {
    if (error) {
      const fallbackPath = path.join(docsRoot, "index.html");
      fs.readFile(fallbackPath, (fallbackError, fallbackData) => {
        if (fallbackError) {
          send(response, 404, "Not found");
          return;
        }

        send(response, 200, fallbackData, mimeTypes[".html"]);
      });
      return;
    }

    const contentType = mimeTypes[path.extname(filePath).toLowerCase()] || "application/octet-stream";
    send(response, 200, data, contentType);
  });
});

server.listen(port, "0.0.0.0", () => {
  console.log(`RegionGlobe preview listening on port ${port}`);
});
