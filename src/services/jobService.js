import { supabase } from '../supabase';

// Fetch jobs within 1.0 km of worker coordinates
export async function fetchNearbyJobs(latitude, longitude, radiusMeters = 1000) {
  const { data, error } = await supabase.rpc('get_jobs_nearby', {
    user_lat: latitude,
    user_lng: longitude,
    radius_meters: radiusMeters
  });

  if (error) {
    console.error('Error fetching nearby jobs:', error.message);
    return [];
  }
  return data;
}

// Post a new job with geographic point
export async function createJob(jobData) {
  const { title, category, pay_rate, pay_type, address, lat, lng, employer_id } = jobData;

  const { data, error } = await supabase.from('jobs').insert([
    {
      title,
      category,
      pay_rate,
      pay_type,
      address,
      employer_id,
      location: `POINT(${lng} ${lat})`
    }
  ]);

  if (error) throw error;
  return data;
}
