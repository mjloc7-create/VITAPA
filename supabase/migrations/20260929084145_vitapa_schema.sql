-- Enable PostGIS extension for 1.0 km hyper-local search
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Create Jobs Table
CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  pay_rate NUMERIC NOT NULL,
  pay_type TEXT CHECK (pay_type IN ('hourly', 'daily', 'fixed')),
  address TEXT NOT NULL,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  employer_id UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'assigned', 'completed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for spatial radial queries
CREATE INDEX jobs_geo_idx ON public.jobs USING GIST (location);

-- 2. Create RPC Function to Query Jobs Within 1.0 km (1000m)
CREATE OR REPLACE FUNCTION get_jobs_nearby(user_lat DOUBLE PRECISION, user_lng DOUBLE PRECISION, radius_meters DOUBLE PRECISION DEFAULT 1000)
RETURNS TABLE (
  id UUID,
  title TEXT,
  category TEXT,
  pay_rate NUMERIC,
  pay_type TEXT,
  address TEXT,
  dist_meters DOUBLE PRECISION
)
LANGUAGE sql
AS $$
  SELECT 
    id, title, category, pay_rate, pay_type, address,
    ST_Distance(location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS dist_meters
  FROM public.jobs
  WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
  AND status = 'open'
  ORDER BY dist_meters ASC;
$$;
