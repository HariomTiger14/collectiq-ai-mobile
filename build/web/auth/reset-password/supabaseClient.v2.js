import { createClient } from '/auth/reset-password/vendor/supabase-js-v2.js';

const supabaseUrl = 'https://ljrkhamgbgtsicqdisos.supabase.co';
const supabaseAnonKey =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqcmtoYW1nYmd0c2ljcWRpc29zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3MTQ5MDIsImV4cCI6MjA5ODI5MDkwMn0.rABsv5oj1l81FAyO03-nSdBE7IHqGZ0Wg-BXlN184rU';

const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    detectSessionInUrl: false,
    persistSession: false
  }
});

export { supabase };

// LIVE VERIFICATION SNIPPET
// Paste this in browser console to confirm Cloudflare is serving the new file:
// fetch('/auth/reset-password/supabaseClient.v2.js')
//   .then(r => r.text())
//   .then(t => console.log(t));
