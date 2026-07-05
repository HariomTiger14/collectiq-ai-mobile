(() => {
  const DEFAULT_CONFIG = {
    apiBaseUrl: "https://api-sit.packlox.com",
    frontendUrl: "https://sit.packlox.com",
    refreshIntervalMs: 30000,
  };
  const config = { ...DEFAULT_CONFIG, ...(window.PACKLOX_ADMIN_CONFIG || {}) };
  const root = document.documentElement;
  const themeToggle = document.querySelector("[data-theme-toggle]");
  const toast = document.querySelector("[data-toast]");
  const storedTheme = window.localStorage.getItem("packlox-admin-theme");

  if (storedTheme === "light" || storedTheme === "dark") {
    root.dataset.theme = storedTheme;
  }

  class AdminApiClient {
    constructor(baseUrl) {
      this.baseUrl = baseUrl.replace(/\/+$/, "");
    }

    async getHealth() {
      const startedAt = performance.now();
      const response = await fetch(`${this.baseUrl}/health`, {
        headers: { Accept: "application/json" },
        cache: "no-store",
      });
      const payload = await response.json();
      return {
        payload,
        ok: response.ok,
        latencyMs: Math.max(0, Math.round(performance.now() - startedAt)),
      };
    }

    async getVersion() {
      const response = await fetch(`${this.baseUrl}/version`, {
        headers: { Accept: "application/json" },
        cache: "no-store",
      });
      if (!response.ok) {
        throw new Error(`Version request failed with status ${response.status}`);
      }
      return response.json();
    }
  }

  const client = new AdminApiClient(config.apiBaseUrl);

  const setText = (selector, value) => {
    document.querySelectorAll(selector).forEach((element) => {
      element.textContent = value || "Unavailable";
    });
  };

  const setServiceState = (service, label, state, latencyText) => {
    const pill = document.querySelector(`[data-service-status="${service}"]`);
    const latency = document.querySelector(`[data-service-latency="${service}"]`);
    const card = document.querySelector(`[data-service-card="${service}"]`);
    if (!pill || !card) {
      return;
    }

    pill.textContent = label;
    pill.classList.remove("online", "placeholder", "loading", "offline");
    pill.classList.add(state);
    card.dataset.state = state;
    if (latency) {
      latency.textContent = latencyText;
    }
  };

  const renderVersion = (version) => {
    const environment = version.environment || "unknown";
    const buildTime = version.buildTime || "unknown";
    const commit = version.commit || "unknown";
    const shortCommit = commit === "unknown" ? commit : commit.slice(0, 12);
    const displayVersion = version.version || "unknown";

    setText("[data-environment-badge]", environment.toUpperCase());
    setText("[data-version-pill]", `v${displayVersion}`);
    setText("[data-deployment-timestamp]", buildTime);
    setText('[data-env-field="environment"]', environment.toUpperCase());
    setText('[data-env-field="apiUrl"]', config.apiBaseUrl);
    setText('[data-env-field="frontendUrl"]', config.frontendUrl);
    setText('[data-env-field="buildTime"]', buildTime);
    setText('[data-env-field="commit"]', shortCommit);
    setText('[data-env-field="version"]', displayVersion);
    setServiceState("cloudflare", `v${displayVersion}`, "online", buildTime);
  };

  const renderHealth = ({ payload, ok, latencyMs }) => {
    const services = payload.services || {};
    const latency = payload.latency || {};
    const apiLatency = Number.isFinite(latency.api) ? latency.api : latencyMs;

    setServiceState(
      "api",
      ok && services.api ? "Online" : "Offline",
      ok && services.api ? "online" : "offline",
      `${apiLatency} ms`,
    );
    setServiceState(
      "supabase",
      services.supabase ? "Healthy" : "Offline",
      services.supabase ? "online" : "offline",
      Number.isFinite(latency.supabase) ? `${latency.supabase} ms` : "No response",
    );
    setServiceState(
      "analyzer",
      services.analyzer ? "Healthy" : "Unavailable",
      services.analyzer ? "online" : "offline",
      Number.isFinite(latency.analyzer) ? `${latency.analyzer} ms` : "No response",
    );
  };

  const renderOffline = () => {
    setServiceState("api", "Offline", "offline", "No response");
    setServiceState("supabase", "Offline", "offline", "No response");
    setServiceState("analyzer", "Unavailable", "offline", "No response");
  };

  const showToast = (message) => {
    if (!toast) {
      return;
    }

    toast.textContent = message;
    toast.hidden = false;
    window.clearTimeout(showToast.timeoutId);
    showToast.timeoutId = window.setTimeout(() => {
      toast.hidden = true;
    }, 2600);
  };

  const refreshHealth = async () => {
    try {
      renderHealth(await client.getHealth());
    } catch (error) {
      console.warn("PackLox health refresh failed", error);
      renderOffline();
    }
  };

  const loadVersion = async () => {
    try {
      renderVersion(await client.getVersion());
    } catch (error) {
      console.warn("PackLox version request failed", error);
      renderVersion({
        environment: "unavailable",
        version: "unknown",
        commit: "unknown",
        buildTime: "unavailable",
      });
      setServiceState("cloudflare", "Unavailable", "offline", "No version data");
    }
  };

  document.querySelectorAll("[data-api-link]").forEach((link) => {
    const endpoint = link.dataset.apiLink;
    link.href = `${config.apiBaseUrl}/${endpoint}`;
  });

  document.querySelectorAll("[data-module]").forEach((button) => {
    button.addEventListener("click", () => {
      showToast(`${button.dataset.module} is coming soon.`);
    });
  });

  themeToggle?.addEventListener("click", () => {
    const currentTheme = root.dataset.theme;
    const nextTheme = currentTheme === "dark" ? "light" : "dark";
    root.dataset.theme = nextTheme;
    window.localStorage.setItem("packlox-admin-theme", nextTheme);
  });

  loadVersion();
  refreshHealth();
  window.setInterval(refreshHealth, config.refreshIntervalMs);
})();
