-- DESCRIBE savings_savingsaccount;
-- Question 2: Transaction Frequency Analysis

WITH customer_activity AS (
    SELECT 
        u.id AS customer_id,
        u.name,
        COUNT(s.id) AS total_transactions,
        MIN(s.transaction_date) AS first_txn,
        MAX(s.transaction_date) AS last_txn,
        -- Estimate active tenure in months using transaction date range
        ROUND(
            (TO_DAYS(MAX(s.transaction_date)) - TO_DAYS(MIN(s.transaction_date))) / 30.44 + 1, 
            2
        ) AS tenure_months
    FROM users_customuser u
    JOIN plans_plan p ON u.id = p.owner_id
    JOIN savings_savingsaccount s ON s.plan_id = p.id
    GROUP BY u.id, u.name
),
txn_frequency AS (
    SELECT 
        customer_id,
        total_transactions,
        tenure_months,
        ROUND(total_transactions / tenure_months, 2) AS avg_txn_per_month,
        -- Categorize transaction frequency
        CASE 
            WHEN (total_transactions / tenure_months) >= 10 THEN 'High Frequency'
            WHEN (total_transactions / tenure_months) BETWEEN 3 AND 9.99 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM customer_activity
),
final_summary AS (
    SELECT 
        frequency_category,
        COUNT(*) AS customer_count,
        ROUND(AVG(avg_txn_per_month), 2) AS avg_transactions_per_month
    FROM txn_frequency
    GROUP BY frequency_category
)

-- Final output
SELECT * FROM final_summary
ORDER BY 
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;
