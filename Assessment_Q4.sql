-- Question 4: Customer Lifetime Value Estimation (fixed date field)

SELECT 
    u.id AS customer_id,
    u.name,
    TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE) AS tenure_months,
    COUNT(s.id) AS total_transactions,

    -- Estimating CLV based on provided formula
    ROUND((
        (COUNT(s.id) / NULLIF(TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE), 0)) * 12 *
        (0.001 * AVG(s.confirmed_amount) / 100)  -- 0.1% of avg transaction in Naira
    ), 2) AS estimated_clv

FROM users_customuser u
JOIN savings_savingsaccount s ON u.id = s.owner_id
GROUP BY u.id, u.name
ORDER BY estimated_clv DESC;
