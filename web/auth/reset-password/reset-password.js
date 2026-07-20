import { supabase } from './supabaseClient.v2.js';

const PACKLOX_RESET_PAGE_VERSION = '20260720-boundary-password-fix';

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
  elements.password.disabled = isBusy;
  elements.confirmPassword.disabled = isBusy;
  elements.submit.classList.toggle('loading', isBusy);
  elements.buttonLabel.textContent = isBusy ? 'Updating...' : 'Update password';
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

const PASSWORD_MIN_LENGTH = 12;
const PASSWORD_POLICY_MESSAGE =
  'Use at least 12 characters with uppercase, lowercase, number, and symbol.';


function evaluatePasswordPolicy(password) {
  const checks = {
    hasMinimumLength: password.length >= PASSWORD_MIN_LENGTH,
    hasLowercase: /[a-z]/.test(password),
    hasUppercase: /[A-Z]/.test(password),
    hasNumber: /\d/.test(password),
    hasSymbol: /[^A-Za-z0-9]/.test(password),
  };
  const score = Object.values(checks).filter(Boolean).length;

  return {
    checks,
    score,
    isValid: score === Object.keys(checks).length,
  };
}

function passwordScore(password) {
  return evaluatePasswordPolicy(password).score;
}

function strengthDetails(policy) {
  if (!policy.score) {
    return { label: 'empty', className: '' };
  }

  if (!policy.isValid && policy.score <= 2) {
    return { label: 'weak', className: 'weak' };
  }

  if (!policy.isValid) {
    return { label: 'medium', className: 'medium' };
  }

  return { label: 'strong', className: 'strong' };
}

function resetPasswordFormState(password, confirmPassword) {
  const policy = evaluatePasswordPolicy(password);
  const passwordMessage = !password
    ? 'Please enter a new password.'
    : policy.isValid
      ? ''
      : PASSWORD_POLICY_MESSAGE;
  const confirmMessage = !confirmPassword
    ? 'Please confirm your new password.'
    : password === confirmPassword
      ? ''
      : 'Passwords do not match.';

  return {
    policy,
    passwordMessage,
    confirmMessage,
    passwordsMatch: Boolean(confirmPassword) && password === confirmPassword,
    canSubmit:
      policy.isValid && Boolean(confirmPassword) && password === confirmPassword,
  };
}

function currentFormState() {
  return resetPasswordFormState(
    elements.password.value,
    elements.confirmPassword.value,
  );
}

function updateStrengthMeter(state = currentFormState()) {
  const details = strengthDetails(state.policy);

  elements.strengthBar.className = details.className
    ? `strength-bar ${details.className}`
    : 'strength-bar';
  elements.strengthLabel.textContent = `Password strength: ${details.label}`;
}

function validatePasswordField({ showErrors = true, state = currentFormState() } = {}) {
  elements.password.setAttribute(
    'aria-invalid',
    String(Boolean(state.passwordMessage)),
  );

  if (showErrors) {
    setFieldMessage(elements.passwordError, state.passwordMessage);
  }

  updateStrengthMeter(state);
  return !state.passwordMessage;
}

function validateConfirmField({ showErrors = true, state = currentFormState() } = {}) {
  elements.confirmPassword.setAttribute(
    'aria-invalid',
    String(Boolean(state.confirmMessage)),
  );

  if (showErrors) {
    setFieldMessage(
      elements.confirmError,
      state.passwordsMatch ? 'Passwords match.' : state.confirmMessage,
      state.passwordsMatch ? 'success' : 'error',
    );
  }

  return !state.confirmMessage;
}

function validateForm({ showErrors = true } = {}) {
  const state = currentFormState();
  validatePasswordField({ showErrors, state });
  validateConfirmField({ showErrors, state });

  return state.canSubmit;
}

function updateSubmitState(forceDisabled = false) {
  const state = currentFormState();
  updateStrengthMeter(state);
  elements.submit.disabled = forceDisabled || !state.canSubmit;
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
      updateSubmitState();
    });
  }

  if (confirmToggle) {
    confirmToggle.addEventListener('click', () => {
      peekPassword(confirmToggle, elements.confirmPassword);
      updateSubmitState();
    });
  }
}

function refreshValidation({ showErrors = true } = {}) {
  clearMessage();
  const state = currentFormState();
  validatePasswordField({ showErrors, state });
  validateConfirmField({ showErrors, state });
  updateSubmitState();
}

function attachStrengthHandlers() {
  for (const eventName of ['input', 'change', 'paste', 'keyup']) {
    elements.password.addEventListener(eventName, () => {
      window.setTimeout(() => refreshValidation(), 0);
    });
    elements.confirmPassword.addEventListener(eventName, () => {
      window.setTimeout(() => refreshValidation(), 0);
    });
  }
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
  refreshValidationAfterBrowserFill();
  window.addEventListener('pageshow', refreshValidationAfterBrowserFill);

  const params = paramsFromUrl();

  if (params.get('error_description')) {
    showMessage(params.get('error_description'));
  } else if (params.get('error')) {
    showMessage(params.get('error'));
  } else if (!hasRecoveryToken()) {
    setMissingTokenMessage();
  }
});
