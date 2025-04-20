-- Fix meal_logs table
ALTER TABLE meal_logs 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS food_name TEXT;

-- Create trigger for meal_logs updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_meal_logs_updated_at ON meal_logs;
CREATE TRIGGER update_meal_logs_updated_at
    BEFORE UPDATE ON meal_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Fix get_most_frequent_foods function
DROP FUNCTION IF EXISTS get_most_frequent_foods(integer);
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
        f.name as food_name,
        COUNT(*) as count,
        SUM(ml.calories) as total_calories,
        AVG(ml.protein) as avg_protein,
        AVG(ml.carbs) as avg_carbs,
        AVG(ml.fat) as avg_fat
    FROM meal_logs ml
    JOIN foods f ON ml.food_id = f.id
    WHERE ml.user_id = auth.uid()
    GROUP BY f.name
    ORDER BY count DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure user_nutrition_goals has default values
INSERT INTO user_nutrition_goals (user_id, daily_calories, daily_protein, daily_carbs, daily_fat)
SELECT 
    id as user_id,
    2000 as daily_calories,
    150 as daily_protein,
    250 as daily_carbs,
    70 as daily_fat
FROM auth.users
WHERE NOT EXISTS (
    SELECT 1 FROM user_nutrition_goals WHERE user_id = auth.users.id
); 