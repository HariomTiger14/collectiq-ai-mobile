(() => {
  const root = document.documentElement;
  const themeToggle = document.querySelector("[data-theme-toggle]");
  const toast = document.querySelector("[data-toast]");
  const deploymentLabels = document.querySelectorAll("[data-deployment-timestamp], [data-deployment-value]");
  const storedTheme = window.localStorage.getItem("packlox-admin-theme");

  if (storedTheme === "light" || storedTheme === "dark") {
    root.dataset.theme = storedTheme;
  }

  const deploymentText = new Date().toISOString();
  deploymentLabels.forEach((label) => {
    label.textContent = deploymentText;
  });

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
})();
