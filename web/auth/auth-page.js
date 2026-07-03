(function () {
  const successResetMessage =
    'Password updated successfully.\n\nReturn to the Packlox app and sign in with your new password.';
  const successCallbackMessage = 'Email confirmed. Open Packlox and sign in.';

  function byId(id) {
    return document.getElementById(id);
  }

  function setMessage(kind, text) {
    const message = byId('message');
    if (!message) return;
    message.className = `message ${kind}`;
    message.textContent = text;
    message.hidden = false;
  }

  function setBusy(isBusy) {
    const submit = byId('submit');
    if (submit) submit.disabled = isBusy;
  }

  function paramsFromLocation(location) {
    const params = new URLSearchParams(location.search || '');
    const hash = location.hash && location.hash.startsWith('#')
      ? location.hash.substring(1)
      : location.hash || '';
    const hashParams = new URLSearchParams(hash);
    hashParams.forEach((value, key) => {
      if (!params.has(key)) params.set(key, value);
    });
    return params;
  }

  function authConfig() {
    const config = window.PACKLOX_AUTH_CONFIG || {};
    return {
      supabaseUrl: (config.supabaseUrl || '').trim(),
      supabaseAnonKey: (config.supabaseAnonKey || '').trim(),
    };
  }

  function client() {
    const config = authConfig();
    if (!config.supabaseUrl || !config.supabaseAnonKey) {
      throw new Error('Packlox auth page is not configured.');
    }
    if (!window.supabase || !window.supabase.createClient) {
      throw new Error('Supabase client failed to load.');
    }
    return window.supabase.createClient(
      config.supabaseUrl,
      config.supabaseAnonKey,
      {
        auth: {
          detectSessionInUrl: false,
          persistSession: false,
        },
      },
    );
  }

  async function establishSession(supabaseClient, params, expectedType) {
    const accessToken = params.get('access_token');
    const refreshToken = params.get('refresh_token');
    if (accessToken && refreshToken) {
      const result = await supabaseClient.auth.setSession({
        access_token: accessToken,
        refresh_token: refreshToken,
      });
      if (result.error) throw result.error;
      return result.data.session || null;
    }

    const tokenHash = params.get('token_hash');
    const type = params.get('type') || expectedType;
    if (tokenHash && type) {
      const result = await supabaseClient.auth.verifyOtp({
        token_hash: tokenHash,
        type,
      });
      if (result.error) throw result.error;
      return result.data.session || null;
    }

    return null;
  }

  function friendlyError(error) {
    const raw = String(error && (error.message || error) || '');
    const lower = raw.toLowerCase();
    if (lower.includes('expired') || lower.includes('invalid')) {
      return 'This link is invalid or expired. Please request a new email.';
    }
    if (lower.includes('configured')) {
      return 'This Packlox auth page is not configured yet.';
    }
    return 'Could not complete the request. Please try again.';
  }

  async function initResetPasswordPage() {
    const params = paramsFromLocation(window.location);
    const error = params.get('error_description') || params.get('error');
    if (error) {
      setMessage('error', friendlyError(error));
      return;
    }

    const form = byId('reset-form');
    if (!form) return;
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const password = byId('password').value;
      const confirmPassword = byId('confirm-password').value;
      if (!password || password.length < 6) {
        setMessage('error', 'Password must be at least 6 characters.');
        return;
      }
      if (password !== confirmPassword) {
        setMessage('error', 'Passwords do not match.');
        return;
      }

      setBusy(true);
      try {
        const supabaseClient = client();
        const session = await establishSession(supabaseClient, params, 'recovery');
        if (!session) {
          throw new Error('Missing recovery session.');
        }
        const result = await supabaseClient.auth.updateUser({ password });
        if (result.error) throw result.error;
        form.hidden = true;
        setMessage('success', successResetMessage);
      } catch (error) {
        setMessage('error', friendlyError(error));
      } finally {
        setBusy(false);
      }
    });
  }

  async function initCallbackPage() {
    const params = paramsFromLocation(window.location);
    const error = params.get('error_description') || params.get('error');
    if (error) {
      setMessage('error', friendlyError(error));
      return;
    }

    try {
      const supabaseClient = client();
      await establishSession(supabaseClient, params, params.get('type') || 'signup');
      setMessage('success', successCallbackMessage);
    } catch (error) {
      setMessage('error', friendlyError(error));
    }
  }

  window.PackloxAuthPages = {
    paramsFromLocation,
    initResetPasswordPage,
    initCallbackPage,
    messages: {
      successResetMessage,
      successCallbackMessage,
    },
  };
})();
