-- Newly Graduate Hub Database Schema
-- This file contains all the necessary tables and functions for the graduate assistant app

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone_number TEXT,
    profile_image_url TEXT,
    bio TEXT,
    location TEXT,
    university TEXT,
    degree TEXT,
    graduation_year TEXT,
    field_of_study TEXT,
    gpa DECIMAL(3,2),
    skills TEXT[],
    interests TEXT[],
    linkedin_url TEXT,
    github_url TEXT,
    portfolio_url TEXT,
    resume_url TEXT,
    cover_letter_url TEXT,
    is_profile_complete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create jobs table
CREATE TABLE IF NOT EXISTS jobs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    company TEXT NOT NULL,
    company_logo TEXT,
    description TEXT NOT NULL,
    requirements TEXT,
    benefits TEXT,
    location TEXT NOT NULL,
    job_type TEXT NOT NULL CHECK (job_type IN ('fullTime', 'partTime', 'contract', 'internship', 'remote')),
    experience_level TEXT NOT NULL CHECK (experience_level IN ('entryLevel', 'junior', 'midLevel', 'senior')),
    salary_min DECIMAL(10,2),
    salary_max DECIMAL(10,2),
    salary_currency TEXT DEFAULT 'USD',
    skills TEXT[],
    application_url TEXT,
    application_deadline TIMESTAMP WITH TIME ZONE,
    posted_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    contact_email TEXT,
    contact_phone TEXT,
    applications_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create job_applications table
CREATE TABLE IF NOT EXISTS job_applications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'underReview', 'interviewed', 'rejected', 'accepted')),
    cover_letter TEXT,
    resume_url TEXT,
    notes TEXT,
    applied_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(job_id, user_id)
);

-- Create resumes table
CREATE TABLE IF NOT EXISTS resumes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    personal_info JSONB NOT NULL,
    summary TEXT,
    education JSONB DEFAULT '[]',
    experience JSONB DEFAULT '[]',
    skills TEXT[] DEFAULT '{}',
    projects JSONB DEFAULT '[]',
    certifications JSONB DEFAULT '[]',
    languages TEXT[] DEFAULT '{}',
    additional_info TEXT,
    template_id TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('jobAlert', 'applicationUpdate', 'profileUpdate', 'systemMessage', 'reminder', 'networking')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    action_url TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create saved_jobs table
CREATE TABLE IF NOT EXISTS saved_jobs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, job_id)
);

-- Create resume_templates table
CREATE TABLE IF NOT EXISTS resume_templates (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    template_data JSONB NOT NULL,
    preview_image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create analytics_events table
CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    event_name TEXT NOT NULL,
    properties JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create networking table (for future networking features)
CREATE TABLE IF NOT EXISTS connections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    requester_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    requested_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(requester_id, requested_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_jobs_location ON jobs(location);
CREATE INDEX IF NOT EXISTS idx_jobs_job_type ON jobs(job_type);
CREATE INDEX IF NOT EXISTS idx_jobs_experience_level ON jobs(experience_level);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_date ON jobs(posted_date DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_is_active ON jobs(is_active);
CREATE INDEX IF NOT EXISTS idx_jobs_is_featured ON jobs(is_featured);
CREATE INDEX IF NOT EXISTS idx_jobs_skills ON jobs USING GIN(skills);

CREATE INDEX IF NOT EXISTS idx_job_applications_user_id ON job_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_job_id ON job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_status ON job_applications(status);
CREATE INDEX IF NOT EXISTS idx_job_applications_applied_date ON job_applications(applied_date DESC);

CREATE INDEX IF NOT EXISTS idx_resumes_user_id ON resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_resumes_is_default ON resumes(is_default);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_saved_jobs_user_id ON saved_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_jobs_job_id ON saved_jobs(job_id);

CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_event_name ON analytics_events(event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_timestamp ON analytics_events(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_connections_requester_id ON connections(requester_id);
CREATE INDEX IF NOT EXISTS idx_connections_requested_id ON connections(requested_id);
CREATE INDEX IF NOT EXISTS idx_connections_status ON connections(status);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_applications_updated_at BEFORE UPDATE ON job_applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resumes_updated_at BEFORE UPDATE ON resumes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resume_templates_updated_at BEFORE UPDATE ON resume_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_connections_updated_at BEFORE UPDATE ON connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create RPC function to increment application count
CREATE OR REPLACE FUNCTION increment_application_count(job_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE jobs 
    SET applications_count = applications_count + 1 
    WHERE id = job_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, created_at, updated_at)
    VALUES (NEW.id, NEW.email, NOW(), NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Set up Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE connections ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Profiles policies
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Job applications policies
CREATE POLICY "Users can view their own applications" ON job_applications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own applications" ON job_applications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own applications" ON job_applications
    FOR UPDATE USING (auth.uid() = user_id);

-- Resumes policies
CREATE POLICY "Users can view their own resumes" ON resumes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own resumes" ON resumes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own resumes" ON resumes
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own resumes" ON resumes
    FOR DELETE USING (auth.uid() = user_id);

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- Saved jobs policies
CREATE POLICY "Users can view their own saved jobs" ON saved_jobs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own saved jobs" ON saved_jobs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own saved jobs" ON saved_jobs
    FOR DELETE USING (auth.uid() = user_id);

-- Analytics events policies
CREATE POLICY "Users can insert their own analytics events" ON analytics_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own analytics events" ON analytics_events
    FOR SELECT USING (auth.uid() = user_id);

-- Connections policies
CREATE POLICY "Users can view connections involving them" ON connections
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = requested_id);

CREATE POLICY "Users can insert their own connection requests" ON connections
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can update connections involving them" ON connections
    FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = requested_id);

-- Jobs table is public (no RLS needed for reading)
-- But you might want to add RLS for job posting if you allow users to post jobs

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('profiles', 'profiles', true),
    ('resumes', 'resumes', true),
    ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
CREATE POLICY "Users can upload their own profile images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');

CREATE POLICY "Users can update their own profile images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own profile images" ON storage.objects
    FOR DELETE USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload their own resumes" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view resumes" ON storage.objects
    FOR SELECT USING (bucket_id = 'resumes');

CREATE POLICY "Users can update their own resumes" ON storage.objects
    FOR UPDATE USING (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own resumes" ON storage.objects
    FOR DELETE USING (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload their own documents" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view documents" ON storage.objects
    FOR SELECT USING (bucket_id = 'documents');

CREATE POLICY "Users can update their own documents" ON storage.objects
    FOR UPDATE USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own documents" ON storage.objects
    FOR DELETE USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Insert some sample resume templates
INSERT INTO resume_templates (name, description, template_data, is_active) VALUES
    ('Modern Professional', 'A clean and modern resume template perfect for recent graduates', '{"layout": "modern", "colors": ["#2563eb", "#1f2937"], "sections": ["personal", "summary", "education", "experience", "skills", "projects"]}', true),
    ('Classic Traditional', 'A traditional resume format that works well for all industries', '{"layout": "classic", "colors": ["#000000", "#4b5563"], "sections": ["personal", "summary", "education", "experience", "skills"]}', true),
    ('Creative Design', 'A creative template for design and creative roles', '{"layout": "creative", "colors": ["#7c3aed", "#ec4899"], "sections": ["personal", "summary", "education", "experience", "skills", "projects", "certifications"]}', true)
ON CONFLICT DO NOTHING;

-- Create a function to search jobs with full-text search
CREATE OR REPLACE FUNCTION search_jobs(
    search_query TEXT DEFAULT '',
    job_types TEXT[] DEFAULT '{}',
    experience_levels TEXT[] DEFAULT '{}',
    location_filter TEXT DEFAULT '',
    min_salary DECIMAL DEFAULT NULL,
    max_salary DECIMAL DEFAULT NULL,
    skills_filter TEXT[] DEFAULT '{}',
    limit_count INTEGER DEFAULT 20,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    company TEXT,
    company_logo TEXT,
    description TEXT,
    requirements TEXT,
    benefits TEXT,
    location TEXT,
    job_type TEXT,
    experience_level TEXT,
    salary_min DECIMAL,
    salary_max DECIMAL,
    salary_currency TEXT,
    skills TEXT[],
    application_url TEXT,
    application_deadline TIMESTAMP WITH TIME ZONE,
    posted_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN,
    contact_email TEXT,
    contact_phone TEXT,
    applications_count INTEGER,
    is_featured BOOLEAN,
    tags TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT j.*
    FROM jobs j
    WHERE j.is_active = true
        AND (search_query = '' OR 
             j.title ILIKE '%' || search_query || '%' OR 
             j.company ILIKE '%' || search_query || '%' OR 
             j.description ILIKE '%' || search_query || '%')
        AND (array_length(job_types, 1) IS NULL OR j.job_type = ANY(job_types))
        AND (array_length(experience_levels, 1) IS NULL OR j.experience_level = ANY(experience_levels))
        AND (location_filter = '' OR j.location ILIKE '%' || location_filter || '%')
        AND (min_salary IS NULL OR j.salary_min >= min_salary)
        AND (max_salary IS NULL OR j.salary_max <= max_salary)
        AND (array_length(skills_filter, 1) IS NULL OR j.skills && skills_filter)
    ORDER BY j.is_featured DESC, j.posted_date DESC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql;

-- Create a function to get job recommendations for a user
CREATE OR REPLACE FUNCTION get_job_recommendations(user_uuid UUID, limit_count INTEGER DEFAULT 20)
RETURNS TABLE (
    id UUID,
    title TEXT,
    company TEXT,
    company_logo TEXT,
    description TEXT,
    location TEXT,
    job_type TEXT,
    experience_level TEXT,
    salary_min DECIMAL,
    salary_max DECIMAL,
    skills TEXT[],
    posted_date TIMESTAMP WITH TIME ZONE,
    is_featured BOOLEAN,
    match_score INTEGER
) AS $$
DECLARE
    user_skills TEXT[];
    user_location TEXT;
    user_field_of_study TEXT;
BEGIN
    -- Get user profile data
    SELECT p.skills, p.location, p.field_of_study
    INTO user_skills, user_location, user_field_of_study
    FROM profiles p
    WHERE p.id = user_uuid;

    RETURN QUERY
    SELECT 
        j.id,
        j.title,
        j.company,
        j.company_logo,
        j.description,
        j.location,
        j.job_type,
        j.experience_level,
        j.salary_min,
        j.salary_max,
        j.skills,
        j.posted_date,
        j.is_featured,
        -- Calculate match score based on skills, location, and field
        (
            CASE WHEN j.skills && user_skills THEN 3 ELSE 0 END +
            CASE WHEN user_location IS NOT NULL AND j.location ILIKE '%' || user_location || '%' THEN 2 ELSE 0 END +
            CASE WHEN user_field_of_study IS NOT NULL AND (j.title ILIKE '%' || user_field_of_study || '%' OR j.description ILIKE '%' || user_field_of_study || '%') THEN 1 ELSE 0 END
        ) as match_score
    FROM jobs j
    WHERE j.is_active = true
        AND j.id NOT IN (
            SELECT ja.job_id 
            FROM job_applications ja 
            WHERE ja.user_id = user_uuid
        )
    ORDER BY match_score DESC, j.is_featured DESC, j.posted_date DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;