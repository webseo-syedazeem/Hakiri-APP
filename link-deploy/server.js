const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = process.env.PORT || 3000;

const routes = {
  "/": "marketing.html",
  "/support": "support.html",
  "/marketing": "marketing.html",
  "/privacy": "privacy.html",
  "/terms": "terms.html",
  "/delete-account": "delete-account.html",
  "/admin-reports": "admin-reports.html",
};

const resolveFile = (fileName) => {
  const candidates = [
    path.join(__dirname, fileName),
    path.join(process.cwd(), fileName),
    path.join(__dirname, "public", fileName),
    path.join(process.cwd(), "public", fileName),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  return candidates[0];
};

const server = http.createServer((req, res) => {
  const urlPath = req.url.split("?")[0].replace(/\/$/, "") || "/";
  const fileName = routes[urlPath] || (routes[urlPath + "/"] ? routes[urlPath + "/"] : null);

  if (fileName) {
    const filePath = resolveFile(fileName);
    fs.readFile(filePath, "utf8", (err, content) => {
      if (err) {
        res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
        return res.end(`<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=/marketing"></head><body>Redirecting to <a href="/marketing">Marketing</a></body></html>`);
      }
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      res.end(content);
    });
  } else {
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("404 Not Found");
  }
});

server.listen(PORT, () => {
  console.log(`Hakkiri Web running at http://localhost:${PORT}`);
  console.log(`- Support:        http://localhost:${PORT}/support`);
  console.log(`- Marketing:      http://localhost:${PORT}/marketing`);
  console.log(`- Privacy:        http://localhost:${PORT}/privacy`);
  console.log(`- Delete Account: http://localhost:${PORT}/delete-account`);
});
