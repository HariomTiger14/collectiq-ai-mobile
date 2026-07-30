(() => {
  const DEFAULT_CONFIG = {
    apiBaseUrl: "https://api-sit.packlox.com",
    frontendUrl: "https://sit.packlox.com",
    refreshIntervalMs: 30000,
  };

  class AdminApiClient {
    constructor(baseUrl) {
      this.baseUrl = baseUrl.replace(/\/+$/, "");
    }

    adminHeaders(token) {
      return {
        Accept: "application/json",
        "X-Admin-Token": token,
      };
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

    async getPricingHealth(token) {
      const response = await fetch(`${this.baseUrl}/admin/pricing/health`, {
        headers: this.adminHeaders(token),
        cache: "no-store",
      });
      return this.parseJsonResponse(response);
    }

    async importPriceCharting({ token, source, dryRun }) {
      const params = new URLSearchParams({
        dryRun: String(dryRun),
        timeoutSeconds: "180",
      });
      if (source) {
        params.set("source", source);
      }
      const response = await fetch(`${this.baseUrl}/admin/pricecharting/import?${params}`, {
        method: "POST",
        headers: this.adminHeaders(token),
      });
      return this.parseJsonResponse(response);
    }

    async searchCatalog(query) {
      const params = new URLSearchParams({
        q: query,
        limit: "12",
      });
      const response = await fetch(`${this.baseUrl}/api/pricing/catalog/search?${params}`, {
        headers: { Accept: "application/json" },
        cache: "no-store",
      });
      return this.parseJsonResponse(response);
    }

    async quotePricing(payload) {
      const response = await fetch(`${this.baseUrl}/api/pricing/quote`, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });
      return this.parseJsonResponse(response);
    }

    async parseJsonResponse(response) {
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) {
        const detail = payload.detail || payload.error || {};
        const message = detail.message || payload.message || `Request failed with status ${response.status}`;
        const error = new Error(message);
        error.payload = payload;
        error.status = response.status;
        throw error;
      }
      return payload;
    }
  }

  const getConfig = () => ({
    ...DEFAULT_CONFIG,
    ...(window.PACKLOX_ADMIN_CONFIG || {}),
  });

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

  const prettyJson = (value) => JSON.stringify(value, null, 2);

  const setOutput = (selector, value) => {
    const element = document.querySelector(selector);
    if (element) {
      element.textContent = typeof value === "string" ? value : prettyJson(value);
    }
  };

  const getAdminToken = () => {
    const input = document.querySelector("[data-admin-token]");
    return (input?.value || "").trim();
  };

  const requireAdminToken = (toast) => {
    const token = getAdminToken();
    if (!token) {
      showToast("Enter the admin token before running protected actions.", toast);
      throw new Error("Admin token is required.");
    }
    return token;
  };

  const renderVersion = (version, config) => {
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
    renderHealthChecks(payload.checks || []);
  };

  const renderHealthChecks = (checks) => {
    const container = document.querySelector("[data-health-checks]");
    if (!container) {
      return;
    }
    if (!checks.length) {
      container.innerHTML = "<p>No detailed checks returned by the backend.</p>";
      return;
    }
    container.innerHTML = checks
      .map((check) => {
        const state = check.healthy ? "online" : check.required ? "offline" : "placeholder";
        const label = check.healthy ? "Healthy" : check.required ? "Required" : "Optional";
        const latency = Number.isFinite(check.latencyMs) ? `${check.latencyMs} ms` : "No latency";
        return `
          <article class="check-row" data-state="${state}">
            <div>
              <strong>${escapeHtml(check.name || "Unnamed check")}</strong>
              <span>${escapeHtml(check.message || "No message")}</span>
            </div>
            <small>${label} · ${latency}</small>
          </article>
        `;
      })
      .join("");
  };

  const renderOffline = () => {
    setServiceState("api", "Offline", "offline", "No response");
    setServiceState("supabase", "Offline", "offline", "No response");
    setServiceState("analyzer", "Unavailable", "offline", "No response");
  };

  const renderPricingHealth = (payload) => {
    const status = document.querySelector("[data-pricing-health-status]");
    if (status) {
      status.textContent = payload.status || "Checked";
      status.classList.remove("loading", "online", "offline", "placeholder");
      status.classList.add(payload.status === "healthy" ? "online" : "placeholder");
    }

    const provider = payload.provider || payload.pricingProvider || payload.activeProvider || "Unknown";
    const cache = payload.cache || payload.cacheStatus || payload.sharedCache || "Unknown";
    const fallback = payload.fallback || payload.fallbackMode || payload.fallbackUsed || "Unknown";
    setText('[data-pricing-field="provider"]', String(provider));
    setText('[data-pricing-field="cache"]', String(cache));
    setText('[data-pricing-field="fallback"]', String(fallback));
    setOutput("[data-pricing-health-output]", payload);
  };

  const renderCatalogResults = (payload) => {
    const body = document.querySelector("[data-catalog-results]");
    if (!body) {
      return;
    }
    const items = payload.items || payload.results || [];
    if (!items.length) {
      body.innerHTML = '<tr><td colspan="4">No catalog matches found.</td></tr>';
      return;
    }
    body.innerHTML = items
      .map((item) => {
        const title = item.title || item.name || item.itemName || "Untitled";
        const source = item.source || item.catalogSource || item.provider || "Unknown";
        const price = item.price || item.marketPrice || item.estimatedValue || item.loosePrice || "N/A";
        const updated = item.updatedAt || item.lastUpdated || item.lastSeenAt || "Unknown";
        return `
          <tr>
            <td>${escapeHtml(String(title))}</td>
            <td>${escapeHtml(String(source))}</td>
            <td>${escapeHtml(String(price))}</td>
            <td>${escapeHtml(String(updated))}</td>
          </tr>
        `;
      })
      .join("");
  };

  const escapeHtml = (value) =>
    value.replace(/[&<>"']/g, (character) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#039;",
    })[character]);

  const showToast = (message, toast) => {
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

  const refreshHealth = async (client) => {
    try {
      renderHealth(await client.getHealth());
    } catch (error) {
      console.warn("PackLox health refresh failed", error);
      renderOffline();
    }
  };

  const loadVersion = async (client, config) => {
    try {
      renderVersion(await client.getVersion(), config);
    } catch (error) {
      console.warn("PackLox version request failed", error);
      renderVersion(
        {
          environment: "unavailable",
          version: "unknown",
          commit: "unknown",
          buildTime: "unavailable",
        },
        config,
      );
      setServiceState("cloudflare", "Unavailable", "offline", "No version data");
    }
  };

  const restoreTheme = (root) => {
    try {
      const storedTheme = window.localStorage.getItem("packlox-admin-theme");
      if (storedTheme === "light" || storedTheme === "dark") {
        root.dataset.theme = storedTheme;
      }
    } catch (error) {
      console.warn("PackLox admin theme storage unavailable", error);
    }
  };

  const initDashboard = () => {
    const config = getConfig();
    const client = new AdminApiClient(config.apiBaseUrl);
    const root = document.documentElement;
    const themeToggle = document.querySelector("[data-theme-toggle]");
    const toast = document.querySelector("[data-toast]");

    restoreTheme(root);
    try {
      const storedToken = window.localStorage.getItem("packlox-admin-token");
      const tokenInput = document.querySelector("[data-admin-token]");
      if (storedToken && tokenInput) {
        tokenInput.value = storedToken;
      }
    } catch (error) {
      console.warn("PackLox admin token storage unavailable", error);
    }

    document.querySelectorAll("[data-api-link]").forEach((link) => {
      const endpoint = link.dataset.apiLink;
      link.href = `${config.apiBaseUrl}/${endpoint}`;
    });

    document.querySelectorAll("[data-module]").forEach((button) => {
      button.addEventListener("click", () => {
        showToast(`${button.dataset.module} is planned for the next admin backend pass.`, toast);
      });
    });

    document.querySelector("[data-save-admin-token]")?.addEventListener("click", () => {
      try {
        window.localStorage.setItem("packlox-admin-token", getAdminToken());
        showToast("Admin token saved in this browser.", toast);
      } catch (error) {
        console.warn("PackLox admin token storage unavailable", error);
        showToast("Token storage is unavailable in this browser.", toast);
      }
    });

    document.querySelector('[data-action="refresh-health"]')?.addEventListener("click", () => {
      refreshHealth(client);
      showToast("Refreshing platform health.", toast);
    });

    document.querySelector('[data-action="open-health"]')?.addEventListener("click", () => {
      window.open(`${config.apiBaseUrl}/health`, "_blank", "noopener");
    });

    document.querySelector('[data-action="pricing-health"]')?.addEventListener("click", async () => {
      try {
        renderPricingHealth(await client.getPricingHealth(requireAdminToken(toast)));
        showToast("Pricing health loaded.", toast);
      } catch (error) {
        console.warn("Pricing health failed", error);
        setOutput("[data-pricing-health-output]", error.payload || error.message);
        showToast(error.message, toast);
      }
    });

    document.querySelector('[data-action="dry-run-import"]')?.addEventListener("click", async () => {
      try {
        const payload = await client.importPriceCharting({
          token: requireAdminToken(toast),
          source: "",
          dryRun: true,
        });
        setOutput("[data-pricecharting-output]", payload);
        showToast("Catalog dry run complete.", toast);
      } catch (error) {
        console.warn("Catalog dry run failed", error);
        setOutput("[data-pricecharting-output]", error.payload || error.message);
        showToast(error.message, toast);
      }
    });

    document.querySelector("[data-pricecharting-form]")?.addEventListener("submit", async (event) => {
      event.preventDefault();
      try {
        const payload = await client.importPriceCharting({
          token: requireAdminToken(toast),
          source: document.querySelector("[data-pricecharting-source]")?.value || "",
          dryRun: Boolean(document.querySelector("[data-pricecharting-dry-run]")?.checked),
        });
        setOutput("[data-pricecharting-output]", payload);
        showToast("PriceCharting import finished.", toast);
      } catch (error) {
        console.warn("PriceCharting import failed", error);
        setOutput("[data-pricecharting-output]", error.payload || error.message);
        showToast(error.message, toast);
      }
    });

    document.querySelector("[data-catalog-search-form]")?.addEventListener("submit", async (event) => {
      event.preventDefault();
      try {
        const query = document.querySelector("[data-catalog-query]")?.value || "";
        renderCatalogResults(await client.searchCatalog(query));
        showToast("Catalog search complete.", toast);
      } catch (error) {
        console.warn("Catalog search failed", error);
        document.querySelector("[data-catalog-results]").innerHTML =
          `<tr><td colspan="4">${escapeHtml(error.message)}</td></tr>`;
        showToast(error.message, toast);
      }
    });

    document.querySelector("[data-pricing-quote-form]")?.addEventListener("submit", async (event) => {
      event.preventDefault();
      try {
        const payload = {
          itemName: document.querySelector("[data-quote-name]")?.value || "",
          category: document.querySelector("[data-quote-category]")?.value || "",
          condition: document.querySelector("[data-quote-condition]")?.value || "",
          displayCurrency: document.querySelector("[data-quote-currency]")?.value || "AUD",
        };
        setOutput("[data-pricing-quote-output]", await client.quotePricing(payload));
        showToast("Pricing quote loaded.", toast);
      } catch (error) {
        console.warn("Pricing quote failed", error);
        setOutput("[data-pricing-quote-output]", error.payload || error.message);
        showToast(error.message, toast);
      }
    });

    themeToggle?.addEventListener("click", () => {
      const currentTheme = root.dataset.theme;
      const nextTheme = currentTheme === "dark" ? "light" : "dark";
      root.dataset.theme = nextTheme;
      try {
        window.localStorage.setItem("packlox-admin-theme", nextTheme);
      } catch (error) {
        console.warn("PackLox admin theme storage unavailable", error);
      }
    });

    window.PACKLOX_ADMIN_READY = true;
    window.dispatchEvent(new CustomEvent("packlox-admin-ready"));
    console.info("PackLox admin dashboard polling started", {
      apiBaseUrl: config.apiBaseUrl,
      refreshIntervalMs: config.refreshIntervalMs,
    });

    loadVersion(client, config);
    refreshHealth(client);
    window.setInterval(() => refreshHealth(client), config.refreshIntervalMs);
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initDashboard, { once: true });
  } else {
    initDashboard();
  }
})();
