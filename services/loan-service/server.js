const express = require("express");
const app = express();
const port = 7000;

app.get("/", (req, res) => {
  res.json({ message: "Loan Service Running" });
});

app.get("/loans", (req, res) => {
  res.json({
    active_loans: 2,
    pending_approvals: 1,
    total_disbursed: "2000 USD"
  });
});

app.listen(port, () => console.log(`Loan service running on ${port}`));
