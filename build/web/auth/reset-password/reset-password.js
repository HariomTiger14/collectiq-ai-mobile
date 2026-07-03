import { supabase } from './supabaseClient.js';

const redirectSeconds = 5;
const loginPath = '/auth/login';
const successMessage =
  'Password updated successfully. Redirecting you to sign in.';

const elements = {};

function getElement(id) {
  return document.getElementById(id);
}

function cacheElements() {
  elements.form = getElement('reset-form');
  elements.password = getElement('password');
  elements.confirmPassword = getElement('confirm-password');
  elements.passwordError = getElement('password-error');
  elements.confirmError = getElement('confirm-error');
  elements.strengthBar = getElement('strength-bar');
  elements.strengthLabel = getElement('strength-label');
  elements.message = getElement('message');
  elements.submit = getElement('submit');
  elements.buttonLabel = elements.submit.querySelector('.button-label');
  elements.redirectStatus = getElement('redirect-status');
  elements.toggleButtons = document.querySelectorAll('.toggle-password');
}

function setMessage(text, type = 'error') {
  elements.message.textContent = text;
  elements.message.className = `message ${type}`;
  elements.message.hidden = false;
}

function setMissingTokenMessage() {
  elements.message.className = 'message error';
  elements.message.replaceChildren(
    document.createTextNode(
      'This reset link is missing its recovery token. ',
    ),
  );

  const link = document.createElement('a');
  link.href = '/auth/login';
  link.textContent = 'Request a new password reset email.';
  elements.message.appendChild(link);
  elements.message.hidden = false;
}

function clearMessage() {
  elements.message.textContent = '';
  elements.message.hidden = true;
  elements.message.className = 'message';
}

function setFieldMessage(element, message, type = 'error') {
  element.textContent = message;
  element.className = message ? `field-message ${type}` : 'field-message';
}

function setBusy(isBusy) {
  elements.submit.disabled = isBusy;
  elements.password.disabled = isBusy;
  elements.confirmPassword.disabled = isBusy;
  elements.submit.classList.toggle('loading', isBusy);
  elements.buttonLabel.textContent = isBusy ? 'Updating password' : 'Update password';
}

function hashParamsFromUrl() {
  return new URLSearchParams(window.location.hash.substring(1));
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

function extractTokenFromHash() {
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

const recoveryHashTokens = extractTokenFromHash;

function getRecoveryToken(params) {
  return params.get('token') || params.get('token_hash');
}

function hasRecoveryToken() {
  const params = paramsFromUrl();
  const hashTokens = recoveryHashTokens();

  return Boolean(
    (hashTokens.accessToken && hashTokens.refreshToken) ||
      (params.get('access_token') && params.get('refresh_token')) ||
      getRecoveryToken(params),
  );
}

async function establishSessionWithTokens(accessToken, refreshToken) {
  const { data, error } = await supabase.auth.setSession({
    access_token: accessToken,
    refresh_token: refreshToken,
  });

  if (error) {
    throw error;
  }

  return data.session;
}

async function establishRecoverySession() {
  const params = paramsFromUrl();
  const hashTokens = recoveryHashTokens();

  if (hashTokens.accessToken && hashTokens.refreshToken) {
    return establishSessionWithTokens(
      hashTokens.accessToken,
      hashTokens.refreshToken,
    );
  }

  const queryAccessToken = params.get('access_token');
  const queryRefreshToken = params.get('refresh_token');

  if (queryAccessToken && queryRefreshToken) {
    return establishSessionWithTokens(queryAccessToken, queryRefreshToken);
  }

  const recoveryToken = getRecoveryToken(params);

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

function passwordScore(password) {
  let score = 0;

  if (password.length >= 8) score += 1;
  if (/[a-z]/.test(password)) score += 1;
  if (/[A-Z]/.test(password)) score += 1;
  if (/\d/.test(password)) score += 1;
  if (/[^A-Za-z0-9]/.test(password)) score += 1;

  return Math.min(score, 4);
}

function strengthDetails(score) {
  if (score <= 1) {
    return { label: 'weak', className: 'weak' };
  }

  if (score === 2) {
    return { label: 'medium', className: 'medium' };
  }

  if (score === 3) {
    return { label: 'strong', className: 'strong' };
  }

  return { label: 'very strong', className: 'very-strong' };
}

function passwordValidationMessage(password) {
  if (!password) return 'Please enter a new password.';
  if (password.length < 8) return 'Password must be at least 8 characters.';
  if (!/[a-z]/.test(password)) return 'Add at least one lowercase letter.';
  if (!/[A-Z]/.test(password)) return 'Add at least one uppercase letter.';
  if (!/\d/.test(password)) return 'Add at least one number.';
  if (!/[^A-Za-z0-9]/.test(password)) return 'Add at least one symbol.';

  return '';
}

function updateStrengthMeter() {
  const password = elements.password.value;
  const score = passwordScore(password);
  const details = strengthDetails(score);

  elements.strengthBar.className = password
    ? `strength-bar ${details.className}`
    : 'strength-bar';
  elements.strengthLabel.textContent = password
    ? `Password strength: ${details.label}`
    : 'Password strength: empty';
}

function validatePasswordField() {
  const message = passwordValidationMessage(elements.password.value);
  elements.password.setAttribute('aria-invalid', String(Boolean(message)));
  setFieldMessage(elements.passwordError, message);
  updateStrengthMeter();

  return !message;
}

function validateConfirmField() {
  const password = elements.password.value;
  const confirmPassword = elements.confirmPassword.value;

  if (!confirmPassword) {
    elements.confirmPassword.setAttribute('aria-invalid', 'true');
    setFieldMessage(elements.confirmError, 'Please confirm your new password.');
    return false;
  }

  if (password !== confirmPassword) {
    elements.confirmPassword.setAttribute('aria-invalid', 'true');
    setFieldMessage(elements.confirmError, 'Passwords do not match.');
    return false;
  }

  elements.confirmPassword.setAttribute('aria-invalid', 'false');
  setFieldMessage(elements.confirmError, 'Passwords match.', 'success');
  return true;
}

function validateForm() {
  const isPasswordValid = validatePasswordField();
  const isConfirmValid = validateConfirmField();

  return isPasswordValid && isConfirmValid;
}

function friendlyError(error) {
  const message = (error?.message || '').toLowerCase();

  if (message.includes('expired')) {
    return 'This reset link has expired. Please request a new password reset email.';
  }

  if (
    message.includes('invalid') ||
    message.includes('token') ||
    message.includes('session')
  ) {
    return 'This reset link is invalid. Please request a new password reset email.';
  }

  if (message.includes('password')) {
    return 'This password does not meet the security requirements.';
  }

  if (
    message.includes('network') ||
    message.includes('failed to fetch') ||
    message.includes('timeout')
  ) {
    return 'Network error. Please check your connection and try again.';
  }

  return error?.message || 'Unable to update password. Please try again.';
}

function startRedirectCountdown() {
  let secondsRemaining = redirectSeconds;

  elements.redirectStatus.textContent = `Redirecting to sign in in ${secondsRemaining}s.`;

  const timer = window.setInterval(() => {
    secondsRemaining -= 1;
    elements.redirectStatus.textContent = `Redirecting to sign in in ${secondsRemaining}s.`;

    if (secondsRemaining <= 0) {
      window.clearInterval(timer);
      window.location.assign(loginPath);
    }
  }, 1000);
}

async function clearRecoverySession() {
  try {
    await supabase.auth.signOut();
  } catch (_) {
    // The password has already been updated; sign-out cleanup is best effort.
  }
}

async function submitNewPassword(event) {
  event.preventDefault();
  clearMessage();

  if (!hasRecoveryToken()) {
    setMissingTokenMessage();
    return;
  }

  if (!validateForm()) {
    setMessage('Please fix the highlighted fields before continuing.');
    return;
  }

  setBusy(true);

  try {
    const session = await establishRecoverySession();

    if (!session) {
      throw new Error('Password reset token is missing or expired.');
    }

    const { error } = await supabase.auth.updateUser({
      password: elements.password.value,
    });

    if (error) {
      throw error;
    }

    await clearRecoverySession();
    elements.form.hidden = true;
    setMessage(successMessage, 'success');
    startRedirectCountdown();
  } catch (error) {
    setMessage(friendlyError(error));
  } finally {
    setBusy(false);
  }
}

function peekPassword(button, input) {
  const isHidden = input.type === 'password';

  input.type = isHidden ? 'text' : 'password';
  button.setAttribute(
    'aria-label',
    `${isHidden ? 'Hide' : 'Show'} ${
      input.id === 'password' ? 'new' : 'confirmed'
    } password`,
  );
}

function attachPeekHandlers() {
  const passwordToggle =
    getElement('togglePassword') ||
    document.querySelector('[data-target="password"]');
  const confirmToggle =
    getElement('toggleConfirmPassword') ||
    document.querySelector('[data-target="confirm-password"]');

  if (passwordToggle) {
    passwordToggle.addEventListener('click', () => {
      peekPassword(passwordToggle, elements.password);
    });
  }

  if (confirmToggle) {
    confirmToggle.addEventListener('click', () => {
      peekPassword(confirmToggle, elements.confirmPassword);
    });
  }
}

function attachStrengthHandlers() {
  elements.password.addEventListener('input', () => {
    updateStrengthMeter();
    validatePasswordField();

    if (elements.confirmPassword.value) {
      validateConfirmField();
    }
  });

  elements.confirmPassword.addEventListener('input', validateConfirmField);
}

function attachSubmitHandler() {
  elements.form.addEventListener('submit', submitNewPassword);
}

document.addEventListener('DOMContentLoaded', () => {
  if (!supabase) {
    console.error('Supabase not ready — handlers not attached');
    return;
  }

  cacheElements();
  attachPeekHandlers();
  attachStrengthHandlers();
  attachSubmitHandler();
  updateStrengthMeter();

  const params = paramsFromUrl();

  if (params.get('error_description')) {
    setMessage(params.get('error_description'));
  } else if (params.get('error')) {
    setMessage(params.get('error'));
  } else if (!hasRecoveryToken()) {
    setMissingTokenMessage();
  }
});
