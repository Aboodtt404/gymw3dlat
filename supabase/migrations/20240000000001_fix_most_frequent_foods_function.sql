-- First drop the existing function
DROP FUNCTION IF EXISTS get_most_frequent_foods(integer);

-- Recreate the function with the correct return type
CREATE OR REPLACE FUNCTION get_most_frequent_foods(limit_count INTEGER)
RETURNS TABLE (
    food_name TEXT,
    count BIGINT,
    total_calories DECIMAL,
    avg_protein DECIMAL,
    avg_carbs DECIMAL,
    avg_fat DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ml.food_name,
        COUNT(*) as count,
        SUM(ml.calories) as total_calories,
        AVG(ml.protein) as avg_protein,
        AVG(ml.carbs) as avg_carbs,
        AVG(ml.fat) as avg_fat
    FROM meal_logs ml
    WHERE ml.user_id = auth.uid()  -- Add RLS for security
    GROUP BY ml.food_name
    ORDER BY count DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 