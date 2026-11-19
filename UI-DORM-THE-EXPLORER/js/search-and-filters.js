(() => {
  const dorms = window.DORMITORY_DATA || [];
  const searchInput = document.getElementById("search-query");
  const resultsGrid = document.getElementById("results-grid");
  const resultsCount = document.getElementById("results-count");
  const emptyState = document.getElementById("empty-state");
  const resultLabel = document.getElementById("result-label");
  const viewResultsButton = document.getElementById("view-results");
  const sortSelect = document.getElementById("sort-results");
  const campusSelect = document.getElementById("campus-filter");
  const ratingSelect = document.getElementById("rating-filter");
  const clearSearchButton = document.getElementById("clear-search");

  const state = { query: "", price: "", slots: "", campus: "", rating: 0, amenities: [] };
  const params = new URLSearchParams(window.location.search);
  state.query = (params.get("q") || "").trim();
  searchInput.value = state.query;

  const money = new Intl.NumberFormat("en-PH", { maximumFractionDigits: 0 });
  const escapeHtml = value => String(value ?? "").replace(/[&<>"']/g, character => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  })[character]);

  function matchesDorm(dorm) {
    const query = state.query.toLocaleLowerCase();
    const campusNames = { alangilan: "Alangilan Campus", "pablo-borbon": "Pablo Borbon Campus", lpu: "LPU" };
    const amenityNames = { wifi: "WiFi", own_cr: "Own CR bathroom", aircon: "Air conditioning", kitchen: "Kitchen", parking: "Parking", laundry: "Laundry" };
    const searchable = [
      dorm.name, dorm.address, dorm.description, dorm.proximityLabel,
      ...(dorm.amenities || []).map(amenity => amenityNames[amenity] || amenity),
      ...(dorm.campuses || []).map(campus => campusNames[campus] || campus)
    ].join(" ").toLocaleLowerCase();
    if (query && !searchable.includes(query)) return false;

    if (state.price === "budget" && dorm.monthlyPrice > 3000) return false;
    if (state.price === "mid" && (dorm.monthlyPrice < 3000 || dorm.monthlyPrice > 5000)) return false;
    if (state.price === "premium" && dorm.monthlyPrice < 5000) return false;

    if (state.slots === "1-2" && !(dorm.availableSlots >= 1 && dorm.availableSlots <= 2)) return false;
    if (state.slots === "3-4" && !(dorm.availableSlots >= 3 && dorm.availableSlots <= 4)) return false;
    if (state.slots === "5-plus" && dorm.availableSlots < 5) return false;

    if (state.campus && !(dorm.campuses || []).includes(state.campus)) return false;
    if (state.rating && (dorm.averageRating || 0) < state.rating) return false;
    return state.amenities.every(amenity => (dorm.amenities || []).includes(amenity));
  }

  function sortDorms(items) {
    const sorted = [...items];
    switch (sortSelect.value) {
      case "price-low": return sorted.sort((a, b) => a.monthlyPrice - b.monthlyPrice);
      case "price-high": return sorted.sort((a, b) => b.monthlyPrice - a.monthlyPrice);
      case "rating": return sorted.sort((a, b) => (b.averageRating || 0) - (a.averageRating || 0));
      default:
        return sorted.sort((a, b) =>
          Number(b.availableSlots > 0) - Number(a.availableSlots > 0) ||
          (b.averageRating || 0) - (a.averageRating || 0)
        );
    }
  }

  function renderCard(dorm) {
    const full = dorm.availableSlots <= 0;
    const photo = dorm.photoUrls?.[0] || "assets/dorm-placeholder.svg";
    const status = full ? "FULL (0 slots)" : dorm.availableSlots + (dorm.availableSlots === 1 ? " slot left" : " slots left");
    return `<a class="dorm-card" href="Dorm%20Details.html?id=${encodeURIComponent(dorm.id)}" aria-label="View ${escapeHtml(dorm.name)} details">
      <div class="card-photo">
        <img src="${escapeHtml(photo)}" alt="Photo of ${escapeHtml(dorm.name)}" loading="lazy" onerror="this.onerror=null;this.src='assets/dorm-placeholder.svg'">
        <span class="availability-badge ${full ? "full" : ""}">${escapeHtml(status)}</span>
      </div>
      <div class="card-content">
        <div>
          <div class="card-distance"><span class="material-symbols-outlined" aria-hidden="true" style="font-size:12px;vertical-align:-2px">near_me</span> ${escapeHtml(dorm.proximityLabel || "Batangas City")}</div>
          <h3 class="card-title">${escapeHtml(dorm.name)}</h3>
          <p class="card-address">${escapeHtml(dorm.address)}</p>
        </div>
        <div class="card-meta">
          <span class="card-price">₱${money.format(dorm.monthlyPrice)}<small> /mo</small></span>
          <span class="card-rating"><span class="material-symbols-outlined" aria-hidden="true">star</span>${Number(dorm.averageRating || 0).toFixed(1)}</span>
        </div>
      </div>
    </a>`;
  }

  function render() {
    state.query = searchInput.value.trim();
    state.price = document.querySelector('[data-filter-group="price"] [aria-pressed="true"]')?.dataset.value || "";
    state.slots = document.querySelector('[data-filter-group="slots"] [aria-pressed="true"]')?.dataset.value || "";
    state.campus = campusSelect.value;
    state.rating = Number(ratingSelect.value);
    state.amenities = [...document.querySelectorAll('input[name="amenity"]:checked')].map(input => input.value);

    const matched = sortDorms(dorms.filter(matchesDorm));
    resultsGrid.innerHTML = matched.map(renderCard).join("");
    resultsCount.textContent = `Showing ${matched.length} of ${dorms.length} verified dorms`;
    resultLabel.textContent = `${matched.length} ${matched.length === 1 ? "result" : "results"}`;
    viewResultsButton.setAttribute("aria-label", `View ${matched.length} matching dorms`);
    emptyState.hidden = matched.length !== 0;
    resultsGrid.hidden = matched.length === 0;
  }

  function clearFilters() {
    searchInput.value = "";
    campusSelect.value = "";
    ratingSelect.value = "0";
    document.querySelectorAll('[data-filter-group] .choice-button').forEach(button => {
      button.setAttribute("aria-pressed", button.dataset.value === "" ? "true" : "false");
    });
    document.querySelectorAll('input[name="amenity"]').forEach(input => { input.checked = false; });
    sortSelect.value = "recommended";
    render();
  }

  document.querySelectorAll("[data-filter-group]").forEach(group => {
    group.addEventListener("click", event => {
      const button = event.target.closest(".choice-button");
      if (!button) return;
      group.querySelectorAll(".choice-button").forEach(option => option.setAttribute("aria-pressed", "false"));
      button.setAttribute("aria-pressed", "true");
      render();
    });
  });

  document.getElementById("search-form").addEventListener("submit", event => {
    event.preventDefault();
    render();
  });
  searchInput.addEventListener("input", render);
  campusSelect.addEventListener("change", render);
  ratingSelect.addEventListener("change", render);
  sortSelect.addEventListener("change", render);
  document.querySelectorAll('input[name="amenity"]').forEach(input => input.addEventListener("change", render));
  document.getElementById("reset-filters").addEventListener("click", clearFilters);
  document.getElementById("clear-all").addEventListener("click", clearFilters);
  clearSearchButton.addEventListener("click", () => {
    searchInput.value = "";
    searchInput.focus();
    render();
  });
  document.getElementById("view-results").addEventListener("click", () => {
    document.getElementById("results").scrollIntoView({ behavior: "smooth", block: "start" });
  });

  render();
})();
