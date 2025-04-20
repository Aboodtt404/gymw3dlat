-- Add created_at and updated_at columns to meal_logs table
ALTER TABLE meal_logs 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Create trigger to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_meal_logs_updated_at
    BEFORE UPDATE ON meal_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create user_nutrition_goals table
CREATE TABLE IF NOT EXISTS public.user_nutrition_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    daily_calories INTEGER NOT NULL DEFAULT 2000,
    daily_protein DECIMAL NOT NULL DEFAULT 150,
    daily_carbs DECIMAL NOT NULL DEFAULT 250,
    daily_fat DECIMAL NOT NULL DEFAULT 70,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add RLS policies for user_nutrition_goals
ALTER TABLE public.user_nutrition_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own nutrition goals"
    ON public.user_nutrition_goals
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own nutrition goals"
    ON public.user_nutrition_goals
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own nutrition goals"
    ON public.user_nutrition_goals
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Create trigger for user_nutrition_goals updated_at
CREATE TRIGGER update_user_nutrition_goals_updated_at
    BEFORE UPDATE ON user_nutrition_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add food_name column to meal_logs if not exists
ALTER TABLE meal_logs
ADD COLUMN IF NOT EXISTS food_name TEXT; 