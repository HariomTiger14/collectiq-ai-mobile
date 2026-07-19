import { supabase } from './supabaseClient.v2.js';

const minimumPasswordLength = 12;
const elements = {};

function getElement(id) {
  return document.getElementById(id);
}

function cacheElements() {
  elements.formPanel = getElement('form-panel');
  elements.successPanel = getElement('success-panel');
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
}

function showMessage(text, type = 'error') {
  elements.message.textContent = text;
  elements.message.className = `message ${type}`;
  elements.message.hidden = false;
}

function setMissingTokenMessage() {
  elements.message.className = 'message error';
  elements.message.textContent =
    'This reset link is missing or invalid. Return to the PackLox app and request a new password reset email.';
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
  elements.password.disabled = isBusy;
  elements.confirmPassword.disabled = isBusy;
  elements.submit.classList.toggle('loading', isBusy);
  elements.buttonLabel.textContent = isBusy ? 'Updating password' : 'Update password';
  updateSubmitState(isBusy);
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

function passwordProgress(password) {
  if (!password) return 0;
  return Math.min(100, Math.round((password.length / minimumPasswordLength) * 100));
}

function progressDetails(progress) {
  if (progress <= 0) {
    return { label: 'empty', className: '' };
  }

  if (progress < 100) {
    return { label: `${minimumPasswordLength - elements.password.value.length} more characters`, className: 'partial' };
  }

  return { label: 'ready', className: 'ready' };
}

function passwordValidationMessage(password) {
  if (!password) return 'Please enter a new password.';
  if (password.length < minimumPasswordLength) {
    return 'Password must be at least 12 characters.';
  }

  return '';
}

function updateStrengthMeter() {
  const password = elements.password.value;
  const progress = passwordProgress(password);
  const details = progressDetails(progress);

  elements.strengthBar.className = details.className
    ? `strength-bar ${details.className}`
    : 'strength-bar';
  elements.strengthBar.style.width = `${progress}%`;
  elements.strengthLabel.textContent = `Passphrase length: ${details.label}`;
}

function validatePasswordField({ showErrors = true } = {}) {
  const message = passwordValidationMessage(elements.password.value);
  elements.password.setAttribute('aria-invalid', String(Boolean(message)));

  if (showErrors) {
    setFieldMessage(elements.passwordError, message);
  }

  updateStrengthMeter();
  return !message;
}

function validateConfirmField({ showErrors = true } = {}) {
  const password = elements.password.value;
  const confirmPassword = elements.confirmPassword.value;

  if (!confirmPassword) {
    elements.confirmPassword.setAttribute('aria-invalid', 'true');

    if (showErrors) {
      setFieldMessage(elements.confirmError, 'Please confirm your new password.');
    }

    return false;
  }

  if (password !== confirmPassword) {
    elements.confirmPassword.setAttribute('aria-invalid', 'true');

    if (showErrors) {
      setFieldMessage(elements.confirmError, 'Passwords do not match.');
    }

    return false;
  }

  elements.confirmPassword.setAttribute('aria-invalid', 'false');

  if (showErrors) {
    setFieldMessage(elements.confirmError, 'Passwords match.', 'success');
  }

  return true;
}

function validateForm({ showErrors = true } = {}) {
  const isPasswordValid = validatePasswordField({ showErrors });
  const isConfirmValid = validateConfirmField({ showErrors });

  return isPasswordValid && isConfirmValid;
}

function updateSubmitState(forceDisabled = false) {
  elements.submit.disabled = forceDisabled || !validateForm({ showErrors: false });
}

function isSamePasswordResult(error, updateData, beforeUpdatedAt) {
  const message = (error?.message || '').toLowerCase();

  if (
    message.includes('same password') ||
    message.includes('different from the old password') ||
    message.includes('new password should be different')
  ) {
    return true;
  }

  const afterUpdatedAt = updateData?.user?.updated_at;

  return Boolean(beforeUpdatedAt && afterUpdatedAt && beforeUpdatedAt === afterUpdatedAt);
}

function friendlyError(error) {
  const message = (error?.message || '').toLowerCase();

  if (isSamePasswordResult(error)) {
    return 'Your new password cannot be the same as your old password.';
  }

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
    return 'Use a password with at least 12 characters.';
  }

  if (
    message.includes('network') ||
    message.includes('failed to fetch') ||
    message.includes('timeout')
  ) {
    return 'Network error. Please check your connection and try again.';
  }

  return 'Unable to update password. Return to the PackLox app and request a new reset email if this continues.';
}

async function clearRecoverySession() {
  try {
    await supabase.auth.signOut();
  } catch (_) {
    // The password has already been updated; sign-out cleanup is best effort.
  }
}

function showSuccessScreen() {
  elements.formPanel.classList.add('fade-out');

  window.setTimeout(() => {
    elements.formPanel.hidden = true;
    elements.successPanel.hidden = false;
    elements.successPanel.classList.add('fade-in');
  }, 380);
}

async function submitNewPassword(event) {
  event.preventDefault();
  clearMessage();

  if (!hasRecoveryToken()) {
    setMissingTokenMessage();
    return;
  }

  if (!validateForm()) {
    showMessage('Please fix the highlighted fields before continuing.');
    return;
  }

  setBusy(true);

  try {
    const session = await establishRecoverySession();

    if (!session) {
      throw new Error('Password reset token is missing or expired.');
    }

    const beforeUpdatedAt = session.user?.updated_at;
    const { data, error } = await supabase.auth.updateUser({
      password: elements.password.value,
    });

    if (isSamePasswordResult(error, data, beforeUpdatedAt)) {
      showMessage('Your new password cannot be the same as your old password.', 'error');
      return;
    }

    if (error) {
      throw error;
    }

    await clearRecoverySession();
    showSuccessScreen();
  } catch (error) {
    showMessage(friendlyError(error));
  } finally {
    setBusy(false);
  }
}

function peekPassword(button, input) {
  const isHidden = input.type === 'password';

  input.type = isHidden ? 'text' : 'password';
  const label = isHidden ? 'Hide' : 'Show';
  const visibleText = button.querySelector('span');

  if (visibleText) {
    visibleText.textContent = label;
  }

  button.setAttribute(
    'aria-label',
    `${label} ${
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
    clearMessage();
    validatePasswordField();

    if (elements.confirmPassword.value) {
      validateConfirmField();
    }

    updateSubmitState();
  });

  elements.confirmPassword.addEventListener('input', () => {
    clearMessage();
    validateConfirmField();
    updateSubmitState();
  });
}

function attachSubmitHandler() {
  elements.form.addEventListener('submit', submitNewPassword);
}

document.addEventListener('DOMContentLoaded', () => {
  if (!supabase) {
    console.error('Supabase not ready - handlers not attached');
    return;
  }

  cacheElements();
  attachPeekHandlers();
  attachStrengthHandlers();
  attachSubmitHandler();
  updateStrengthMeter();
  updateSubmitState();

  const params = paramsFromUrl();

  if (params.get('error_description')) {
    showMessage(
      'This reset link is invalid or expired. Return to the PackLox app and request a new reset email.',
    );
  } else if (params.get('error')) {
    showMessage(
      'This reset link is invalid or expired. Return to the PackLox app and request a new reset email.',
    );
  } else if (!hasRecoveryToken()) {
    setMissingTokenMessage();
  }
});
