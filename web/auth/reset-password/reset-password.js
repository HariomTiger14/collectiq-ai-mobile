import supabase from './supabaseClient.js';

const successMessage =
  'Password updated successfully. Please return to the app and log in.';

function getElement(id) {
  return document.getElementById(id);
}

function setMessage(text, type = 'error') {
  const message = getElement('message');
  message.textContent = text;
  message.className = `message ${type}`;
  message.hidden = false;
}

function setBusy(isBusy) {
  const submit = getElement('submit');
  const password = getElement('password');
  const confirmPassword = getElement('confirm-password');

  submit.disabled = isBusy;
  password.disabled = isBusy;
  confirmPassword.disabled = isBusy;
  submit.textContent = isBusy ? 'Updating...' : 'Update Password';
}

function paramsFromUrl() {
  const params = new URLSearchParams(window.location.search);
  const hashParams = hashParamsFromUrl();

  for (const [key, value] of hashParams.entries()) {
    if (!params.has(key)) {
      params.set(key, value);
    }
  }

  return params;
}

function hashParamsFromUrl() {
  return new URLSearchParams(window.location.hash.substring(1));
}

function recoveryHashTokens() {
  const hashParams = hashParamsFromUrl();

  return {
    accessToken: hashParams.get('access_token'),
    refreshToken: hashParams.get('refresh_token'),
    expiresAt: hashParams.get('expires_at'),
    expiresIn: hashParams.get('expires_in'),
    tokenType: hashParams.get('token_type'),
    type: hashParams.get('type'),
  };
}

function getRecoveryToken(params) {
  return params.get('token') || params.get('token_hash');
}

async function establishRecoverySession(params) {
  const accessToken = params.get('access_token');
  const refreshToken = params.get('refresh_token');
  const recoveryToken = getRecoveryToken(params);

  if (accessToken && refreshToken) {
    const { data, error } = await supabase.auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    });

    if (error) {
      throw error;
    }

    return data.session;
  }

  if (recoveryToken) {
    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: recoveryToken,
      type: 'recovery',
    });

    if (error) {
      throw error;
    }

    return data.session;
  }

  return null;
}

async function establishHashRecoverySession(hashTokens) {
  if (!hashTokens.accessToken || !hashTokens.refreshToken) {
    return null;
  }

  const { data, error } = await supabase.auth.setSession({
    access_token: hashTokens.accessToken,
    refresh_token: hashTokens.refreshToken,
  });

  if (error) {
    throw error;
  }

  return data.session;
}

function validatePassword(password, confirmPassword) {
  if (!password) {
    return 'Please enter a new password.';
  }

  if (password.length < 6) {
    return 'Password must be at least 6 characters.';
  }

  if (!confirmPassword) {
    return 'Please confirm your new password.';
  }

  if (password !== confirmPassword) {
    return 'Passwords do not match.';
  }

  return null;
}

async function handleSubmit(event) {
  event.preventDefault();

  const params = paramsFromUrl();
  const hashTokens = recoveryHashTokens();
  const hasHashSessionTokens = hashTokens.accessToken && hashTokens.refreshToken;
  const hasQuerySessionTokens =
    params.get('access_token') && params.get('refresh_token');
  const hasToken =
    hasHashSessionTokens || hasQuerySessionTokens || getRecoveryToken(params);

  if (!hasToken) {
    if (!hashTokens.accessToken) {
      setMessage(
        'Password reset access token is missing. Please use the latest reset email.',
      );
      return;
    }

    setMessage(
      'Password reset token is missing. Please use the latest reset email.',
    );
    return;
  }

  const password = getElement('password').value.trim();
  const confirmPassword = getElement('confirm-password').value.trim();
  const validationError = validatePassword(password, confirmPassword);

  if (validationError) {
    setMessage(validationError);
    return;
  }

  setBusy(true);

  try {
    const session = hasHashSessionTokens
      ? await establishHashRecoverySession(hashTokens)
      : await establishRecoverySession(params);

    if (!session) {
      throw new Error('Password reset token is missing or expired.');
    }

    const { error } = await supabase.auth.updateUser({
      password,
    });

    if (error) {
      throw error;
    }

    getElement('reset-form').hidden = true;
    setMessage(successMessage, 'success');
  } catch (error) {
    setMessage(error.message || 'Unable to update password. Please try again.');
  } finally {
    setBusy(false);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const params = paramsFromUrl();
  const hashTokens = recoveryHashTokens();

  if (params.get('error_description')) {
    setMessage(params.get('error_description'));
  } else if (params.get('error')) {
    setMessage(params.get('error'));
  } else if (
    !getRecoveryToken(params) &&
    !(hashTokens.accessToken && hashTokens.refreshToken) &&
    !(params.get('access_token') && params.get('refresh_token'))
  ) {
    if (!hashTokens.accessToken) {
      setMessage(
        'Password reset access token is missing. Please use the latest reset email.',
      );
    } else {
      setMessage(
        'Password reset token is missing. Please use the latest reset email.',
      );
    }
  }

  getElement('reset-form').addEventListener('submit', handleSubmit);
});
