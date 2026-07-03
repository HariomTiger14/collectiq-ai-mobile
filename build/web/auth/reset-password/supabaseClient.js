const supabaseUrl = 'https://ljrkhamgbgtsicqdisos.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqcmtoYW1nYmd0c2ljcWRpc29zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3MTQ5MDIsImV4cCI6MjA5ODI5MDkwMn0.rABsv5oj1l81FAyO03-nSdBE7IHqGZ0Wg-BXlN184rU';

if (!window.supabase) {
  throw new Error('Supabase JavaScript client failed to load.');
}

export const supabase = window.supabase.createClient(
  supabaseUrl,
  supabaseAnonKey,
  {
    auth: {
      detectSessionInUrl: false,
      persistSession: false,
    },
  },
);

export default supabase;
