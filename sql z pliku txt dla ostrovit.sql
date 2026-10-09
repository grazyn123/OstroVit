  1. Przychód miesięczny
    Liczę ile kasy wpada w każdym miesiącu, żeby zobaczyć sezonowość i trend.


SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(amount) AS revenue
FROM orders
GROUP BY
    DATE_TRUNC('month', order_date)
ORDER BY
    month;



    2. Średnia wartość zamówienia (AOV)
    Patrzę ile średnio wydaje klient na jedno zamówienie.


SELECT
    DATE_TRUNC('month', order_date) AS month,
    ROUND(AVG(amount), 2) AS aov
FROM orders
GROUP BY
    DATE_TRUNC('month', order_date)
ORDER BY
    month;



    3. Liczba zamówień miesięcznie
    Po prostu liczę ile zamówień było w każdym miesiącu.


SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS orders_count
FROM orders
GROUP BY
    DATE_TRUNC('month', order_date)
ORDER BY
    month;


    4. Retencja klientów
    Sprawdzam ilu klientów kupiło więcej niż raz.


WITH customer_counts AS (
    SELECT
        customer_id,
        COUNT(*) AS cnt
    FROM orders
    GROUP BY
        customer_id
)
SELECT
    ROUND(
        SUM(CASE WHEN cnt > 1 THEN 1 ELSE 0 END)::numeric
        / COUNT(*) * 100,
        2
    ) AS retention_pct
FROM customer_counts;



    5. Zamówienia z polecenia
    Ile zamówień przyszło „od znajomych”.


SELECT
    COUNT(*) AS referral_orders
FROM orders
WHERE
    referral_flag = TRUE;



    6. Klienci pozyskani z polecenia
    Patrzę, czy referral faktycznie działa — liczę tych, których pierwsze zamówienie było z polecenia.


WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_date
    FROM orders
    GROUP BY
        customer_id
)
SELECT
    COUNT(*) AS new_referral_customers
FROM first_order f
JOIN orders o
    ON f.customer_id = o.customer_id
    AND f.first_date = o.order_date
WHERE
    o.referral_flag = TRUE;



    7. Wzrost miesiąc do miesiąca (m/m)
    Porównuję przychód miesiąc do miesiąca, żeby zobaczyć trend.


WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(amount) AS revenue
    FROM orders
    GROUP BY
        DATE_TRUNC('month', order_date)
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) AS growth_pct
FROM monthly;

    8. TOP klienci
    Kto wydaje najwięcej i robi najwięcej zamówień.


SELECT
    customer_id,
    COUNT(*) AS orders_count,
    SUM(amount) AS total_spent
FROM orders
GROUP BY
    customer_id
ORDER BY
    total_spent DESC
LIMIT 10;



    9. Klienci aktywni w każdym miesiącu
    Tacy „hardcore fans”, którzy kupują regularnie.


WITH monthly_customers AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        customer_id
    FROM orders
    GROUP BY
        DATE_TRUNC('month', order_date),
        customer_id
),
counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT month) AS active_months
    FROM monthly_customers
    GROUP BY
        customer_id
)
SELECT
    customer_id,
    active_months
FROM counts
ORDER BY
    active_months DESC;