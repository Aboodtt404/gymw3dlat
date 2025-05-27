-- Create enum types if they don't exist
DO $$ BEGIN
    CREATE TYPE fitness_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE workout_intensity AS ENUM ('light', 'moderate', 'vigorous', 'extreme');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE recovery_status AS ENUM ('fullyRecovered', 'partiallyRecovered', 'fatigued', 'overreached');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE exercise_category AS ENUM ('chest', 'back', 'shoulders', 'arms', 'legs', 'core', 'cardio', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create indexes if they don't exist
DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_workout_templates_user_id ON public.workout_templates(user_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON public.workout_logs(user_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_workout_logs_template_id ON public.workout_logs(template_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_workout_performance_analysis_user_id ON public.workout_performance_analysis(user_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_workout_performance_analysis_workout_log_id ON public.workout_performance_analysis(workout_log_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Enable RLS if not already enabled
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fitness_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_performance_analysis ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Exercises are viewable by everyone" ON public.exercises;
DROP POLICY IF EXISTS "Users can manage their own workout templates" ON public.workout_templates;
DROP POLICY IF EXISTS "Users can manage their own workout logs" ON public.workout_logs;
DROP POLICY IF EXISTS "Users can manage their own fitness profile" ON public.user_fitness_profiles;
DROP POLICY IF EXISTS "Users can view their own workout performance analysis" ON public.workout_performance_analysis;

-- Create policies
CREATE POLICY "Exercises are viewable by everyone" ON public.exercises
    FOR SELECT USING (true);

CREATE POLICY "Users can manage their own workout templates" ON public.workout_templates
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own workout logs" ON public.workout_logs
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own fitness profile" ON public.user_fitness_profiles
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own workout performance analysis" ON public.workout_performance_analysis
    FOR ALL USING (auth.uid() = user_id); 