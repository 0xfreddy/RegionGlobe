const http = require("http");

const port = Number(process.env.PORT || 3000);
const url = `http://127.0.0.1:${port}/`;
const requiredMarkers = [
  "RegionGlobe Preview",
  "Props Playground",
  "selectedCountryNames",
  "globeTexture"
];

http
  .get(url, (response) => {
    let body = "";

    response.setEncoding("utf8");
    response.on("data", (chunk) => {
      body += chunk;
    });
    response.on("end", () => {
      if (response.statusCode !== 200) {
        console.error(`Expected HTTP 200 from ${url}, got ${response.statusCode}`);
        process.exit(1);
      }

      const missing = requiredMarkers.filter((marker) => !body.includes(marker));
      if (missing.length > 0) {
        console.error(`Preview is missing markers: ${missing.join(", ")}`);
        process.exit(1);
      }

      console.log(`Smoke test passed for ${url}`);
    });
  })
  .on("error", (error) => {
    console.error(`Could not reach ${url}: ${error.message}`);
    process.exit(1);
  });
