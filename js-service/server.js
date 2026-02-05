import express from "express";

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/hello", (req, res) => {
  res.type("text").send("Hello, world!");
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server listening on http://0.0.0.0:${PORT}`);
});
