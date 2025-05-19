-- Question 3: Accounts with no transactions in the last 365 days

-- Get inactive savings accounts
SELECT 
    id AS plan_id,
    owner_id,
    'Savings' AS type,
    MAX(transaction_date) AS last_transaction_date,
    DATEDIFF(CURRENT_DATE, MAX(transaction_date)) AS inactivity_days
FROM savings_savingsaccount
WHERE plan_id IS NOT NULL  -- assuming plan_id links to a savings plan
GROUP BY id, owner_id
HAVING inactivity_days > 365

UNION

-- Get inactive investment plans
SELECT 
    id AS plan_id,
    owner_id,
    'Investment' AS type,
    MAX(created_on) AS last_transaction_date,
    DATEDIFF(CURRENT_DATE, MAX(created_on)) AS inactivity_days
FROM plans_plan
WHERE is_a_fund = 1
GROUP BY id, owner_id
HAVING inactivity_days > 365;
