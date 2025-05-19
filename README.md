## 🔸 **Question 1: High-Value Customers with Multiple Products**

### **Objective:**

Identify customers who:

* Have **at least one funded savings plan** (regular savings),
* Have **at least one funded investment plan** (fund),
* Return:

  * `owner_id`, `name`, `savings_count`, `investment_count`, `total_deposits` (in Naira),
* Sort the result by `total_deposits` descending.

---

## **Approach**

1. **Identify savings plans**:

   * `plans_plan.is_regular_savings = 1`
   * Consider only plans with actual deposits (via `savings_savingsaccount.confirmed_amount > 0`)

2. **Identify investment plans**:

   * `plans_plan.is_a_fund = 1`
   * Also, must have recorded deposits

3. **Join with `users_customuser`** to get names.

4. **Aggregate data**:

   * Count how many unique savings and investment plans per user.
   * Sum all deposits for those users across any plan (savings or investment).

5. **Convert kobo to Naira** by dividing `confirmed_amount` by 100.

---

## **Challenges & Resolutions**

| Challenge                                                       | Resolution                                                                                         |
| --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Need to separate **savings** and **investment** plans           | Used flags: `is_regular_savings` and `is_a_fund` respectively.                                     |
| Avoiding double-counting or overlapping plans                   | Used `COUNT(DISTINCT p.id)` to count unique plans per user.                                        |

---

## 🔸**Question 2: Transaction Frequency Analysis**

### **Objective**

Segment customers by how frequently they make **deposit transactions** into their savings accounts:

* **High Frequency**: ≥ 10 transactions/month
* **Medium Frequency**: 3–9 transactions/month
* **Low Frequency**: ≤ 2 transactions/month

### **Expected Output**

| frequency\_category | customer\_count | avg\_transactions\_per\_month |
| ------------------- | --------------- | ----------------------------- |
| High Frequency      | 250             | 15.2                          |
| Medium Frequency    | 1200            | 5.5                           |

---

## **Approach**

1. **Join `users_customuser` to `savings_savingsaccount`** on user ID (`id` = `owner_id` via `plans_plan`).
2. For each customer:

   * Count total transactions.
   * Determine the time range of their activity (from first to last transaction).
   * Convert that into the number of **months**.
   * Calculate **average transactions per month** = total / months.
3. Categorize each customer using a `CASE` statement.
4. Aggregate the result: count customers per category and calculate average monthly transactions for each group.

---

## **Challenge & Resolution**

| Challenge                                        | Resolution                                                          |
| ------------------------------------------------ | ------------------------------------------------------------------- |
| No direct `owner_id` in `savings_savingsaccount` | Join via `plans_plan` using `plan_id → plans_plan.id → owner_id`    |
| Need to convert days to months                   | Used `TO_DAYS()` difference divided by \~30.44 to estimate months |
| Avoiding division by 0                           | Ensured we only consider customers with valid transaction periods   |

---

## 🔸**Question 3 — Account Inactivity Alert**

### Objective:

Identify all active savings or investment accounts with no inflow transactions in the past 365 days.

### Approach:

1. Extracted relevant records from:

   * `savings_savingsaccount` where `is_regular_savings = 1`
   * `plans_plan` where `is_a_fund = 1`
2. Calculated the most recent transaction date for each account.
3. Used `DATEDIFF` to calculate the number of days since the last transaction.
4. Filtered for accounts with inactivity over 365 days.
5. Combined both results using `UNION`.

### SQL Highlights:

* Used `MAX(created_at)` to identify the last transaction per account.
* Used `DATEDIFF(CURRENT_DATE, MAX(created_at))` to compute inactivity in days.
* Labeled account types explicitly as 'Savings' or 'Investment' for clarity.

### Challenges:

* Some accounts had only a single transaction; we ensured aggregation still worked.
* Ensured date formats in `created_at` columns were valid and not NULL.
* Managed consistent aliasing and column naming across the UNION.

---

## 🔸**Question 4 — Customer Lifetime Value (CLV) Estimation**

### Objective:

Estimate Customer Lifetime Value(CLV) using a simplified model involving transaction volume and tenure.

### Approach:

1. Joined `users_customuser` with `savings_savingsaccount` on `id = owner_id`.
2. Calculated:

   * Tenure in months using `TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE)`.
   * Total number of transactions per customer.
   * Average transaction value using `AVG(confirmed_amount)`.
3. Applied the CLV formula: CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction

4. Converted kobo to naira by dividing `confirmed_amount` by 100.
5. Used 0.1% of transaction value as profit per transaction

### SQL Highlights:

* Used `NULLIF(..., 0)` to avoid division by zero when tenure is zero.
* Included only customers with transactions (via joins with savings).
* Ordered by `estimated_clv DESC` to highlight top-value customers.

### Challenges:

* Assumed all users in the savings table are valid customers — no additional filters applied.
