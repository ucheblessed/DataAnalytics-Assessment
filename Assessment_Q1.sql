-- Question 1: High-Value Customers with Multiple Products

SELECT 
    u.id AS owner_id,
    u.name,
    savings.savings_count,
    investments.investment_count,
    -- Sum of all confirmed deposit amounts (converted from kobo to Naira)
    ROUND(total.total_deposit / 100.0, 2) AS total_deposits
FROM users_customuser u

-- Subquery: Customers with funded savings plans
JOIN (
    SELECT 
        p.owner_id, 
        COUNT(DISTINCT p.id) AS savings_count
    FROM plans_plan p
    JOIN savings_savingsaccount s ON p.id = s.plan_id
    WHERE p.is_regular_savings = 1 AND s.confirmed_amount > 0
    GROUP BY p.owner_id
) savings ON u.id = savings.owner_id

-- Subquery: Customers with funded investment plans
JOIN (
    SELECT 
        p.owner_id, 
        COUNT(DISTINCT p.id) AS investment_count
    FROM plans_plan p
    JOIN savings_savingsaccount s ON p.id = s.plan_id
    WHERE p.is_a_fund = 1 AND s.confirmed_amount > 0
    GROUP BY p.owner_id
) investments ON u.id = investments.owner_id

-- Subquery: Total deposits across all types of plans
JOIN (
    SELECT 
        p.owner_id, 
        SUM(s.confirmed_amount) AS total_deposit
    FROM plans_plan p
    JOIN savings_savingsaccount s ON p.id = s.plan_id
    GROUP BY p.owner_id
) total ON u.id = total.owner_id

-- Order results by deposit value, highest first
ORDER BY total_deposits DESC;
