const http = require("http");

// Define the port
const PORT = 5000;

// Create the server
const server = http.createServer((req, res) => {
  // Set the response header to indicate a JSON response
  res.setHeader("Content-Type", "application/json");

  // Check if the request URL is /hello
  if (req.url === "/hello" && req.method === "GET") {
    // Create a JSON response
    const response = {
      message: "Hello, World! Welcome to the API!",
    };
    // Send the JSON response
    res.statusCode = 200; // Set the status code to 200 (OK)
    res.end(JSON.stringify(response)); // Send the response as a JSON string
  } else {
    // Handle 404 Not Found for other routes
    res.statusCode = 404; // Set the status code to 404 (Not Found)
    res.end(JSON.stringify({ message: "Not Found" })); // Send a 404 response
  }
});

// Start the server and listen on the specified port
server.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
