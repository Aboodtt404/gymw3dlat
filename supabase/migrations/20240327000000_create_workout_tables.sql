-- Create enum types
CREATE TYPE fitness_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');
CREATE TYPE workout_intensity AS ENUM ('light', 'moderate', 'vigorous', 'extreme');
CREATE TYPE recovery_status AS ENUM ('fullyRecovered', 'partiallyRecovered', 'fatigued', 'overreached');
CREATE TYPE exercise_category AS ENUM ('chest', 'back', 'shoulders', 'arms', 'legs', 'core', 'cardio', 'other');

-- Create exercises table
CREATE TABLE public.exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category exercise_category NOT NULL,
    equipment VARCHAR(255),
    video_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Create workout_templates table
CREATE TABLE public.workout_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    exercises JSONB NOT NULL,
    estimated_duration INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Create workout_logs table
CREATE TABLE public.workout_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    template_id UUID REFERENCES public.workout_templates(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    exercises JSONB NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Create user_fitness_profiles table
CREATE TABLE public.user_fitness_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    fitness_level fitness_level NOT NULL DEFAULT 'beginner',
    fitness_goals TEXT[] NOT NULL DEFAULT '{}',
    preferred_exercise_types TEXT[] NOT NULL DEFAULT '{}',
    available_equipment TEXT[] NOT NULL DEFAULT '{}',
    max_workout_duration INTEGER NOT NULL DEFAULT 60,
    injuries TEXT[] NOT NULL DEFAULT '{}',
    strength_levels JSONB NOT NULL DEFAULT '{}',
    cardio_endurance DOUBLE PRECISION NOT NULL DEFAULT 3.0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create workout_performance_analysis table
CREATE TABLE public.workout_performance_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_log_id UUID NOT NULL REFERENCES public.workout_logs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    performance_score DOUBLE PRECISION NOT NULL,
    recovery_status recovery_status NOT NULL,
    exercise_performance JSONB NOT NULL,
    strengths TEXT[] NOT NULL,
    weaknesses TEXT[] NOT NULL,
    recommendations TEXT[] NOT NULL,
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_workout_templates_user_id ON public.workout_templates(user_id);
CREATE INDEX idx_workout_logs_user_id ON public.workout_logs(user_id);
CREATE INDEX idx_workout_logs_template_id ON public.workout_logs(template_id);
CREATE INDEX idx_workout_performance_analysis_user_id ON public.workout_performance_analysis(user_id);
CREATE INDEX idx_workout_performance_analysis_workout_log_id ON public.workout_performance_analysis(workout_log_id);

-- Add RLS (Row Level Security) policies
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fitness_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_performance_analysis ENABLE ROW LEVEL SECURITY;

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