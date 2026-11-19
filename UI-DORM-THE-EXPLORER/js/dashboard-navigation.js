(() => {
  const searchInput = document.getElementById("home-search-input");
  searchInput?.addEventListener("keydown", event => {
    if (event.key !== "Enter") return;
    event.preventDefault();
    const query = searchInput.value.trim();
    const suffix = query ? `?q=${encodeURIComponent(query)}` : "";
    window.location.href = `Search%20and%20Filters.html${suffix}`;
  });

  document.querySelectorAll("[data-dorm-id]").forEach(card => {
    card.setAttribute("role", "link");
    card.setAttribute("tabindex", "0");
    card.style.cursor = "pointer";
    const openDetails = () => {
      window.location.href = `Dorm%20Details.html?id=${encodeURIComponent(card.dataset.dormId)}`;
    };
    card.addEventListener("click", event => {
      if (event.target.closest(".fav-btn")) return;
      openDetails();
    });
    card.addEventListener("keydown", event => {
      if (event.key !== "Enter" && event.key !== " ") return;
      if (event.target.closest(".fav-btn")) return;
      event.preventDefault();
      openDetails();
    });
  });
})();
