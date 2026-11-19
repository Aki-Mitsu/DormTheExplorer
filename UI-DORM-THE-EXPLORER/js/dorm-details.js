(() => {
  const dorms = window.DORMITORY_DATA || [];
  const dormId = new URLSearchParams(window.location.search).get("id");
  const dorm = dorms.find(item => item.id === dormId) || dorms[0];
  if (!dorm) return;

  const setText = (selector, value) => {
    const element = document.querySelector(selector);
    if (element && value != null) element.textContent = value;
  };

  document.title = `${dorm.name} | DormTheExplorer`;
  setText("#dorm-detail-name", dorm.name);
  setText("#dorm-detail-address", dorm.address);
  setText("#dorm-detail-rating", Number(dorm.averageRating || 0).toFixed(1));
  setText("#dorm-detail-review-count", "(sample reviews)");
  setText("#dorm-detail-price", `₱${new Intl.NumberFormat("en-PH").format(dorm.monthlyPrice)}`);
  setText("#dorm-detail-slots", `${dorm.availableSlots} Available / ${dorm.totalSlots} Total Slots`);
  setText("#dorm-detail-about-title", `About ${dorm.name}`);
  setText("#dorm-detail-description", dorm.description);
  setText("#dorm-detail-landlord", dorm.landlordName || "Landlord contact to be added");
  setText("#dorm-detail-phone", dorm.landlordPhone || "Contact details to be added");
  setText("#dorm-detail-map-label", dorm.name);

  const address = dorm.address.includes("Batangas City") ? dorm.address : `${dorm.address}, Batangas City`;
  document.querySelector("[data-location]")?.setAttribute("data-location", address);
  const campusLabels = { alangilan: "BatStateU Alangilan", "pablo-borbon": "BatStateU Pablo Borbon", lpu: "LPU" };
  const nearestCampus = (dorm.campuses || [])[0];
  const distanceKm = nearestCampus ? dorm.campusDistances?.[nearestCampus] : null;
  const campusDistance = distanceKm == null
    ? "Campus distance unavailable"
    : `${distanceKm < 1 ? Math.round(distanceKm * 1000) + "m" : distanceKm.toFixed(1) + "km"} to ${campusLabels[nearestCampus] || nearestCampus}`;
  setText("#dorm-detail-campus-distance", campusDistance);

  const cover = document.querySelector("main img");
  if (cover) {
    cover.src = dorm.photoUrls?.[0] || "assets/dorm-placeholder.svg";
    cover.alt = `Photo of ${dorm.name}`;
    cover.onerror = () => { cover.onerror = null; cover.src = "assets/dorm-placeholder.svg"; };
  }

  const utilities = document.getElementById("dorm-detail-utilities");
  if (utilities) utilities.hidden = !dorm.utilitiesIncluded;

  const amenitiesSection = [...document.querySelectorAll("main section")]
    .find(section => section.querySelector("h3")?.textContent.trim() === "Amenities Overview");
  const amenityKeys = {
    "WiFi": "wifi",
    "Own CR": "own_cr",
    "Air Conditioning": "aircon",
    "Kitchen": "kitchen",
    "Laundry": "laundry",
    "Parking": "parking"
  };
  amenitiesSection?.querySelectorAll(".grid > div").forEach(card => {
    const label = card.querySelector(".truncate")?.textContent.trim();
    const key = amenityKeys[label];
    const included = key && (dorm.amenities || []).includes(key);
    const statusIcon = card.querySelector(".material-symbols-outlined:last-child");
    if (!statusIcon) return;
    statusIcon.textContent = included ? "check_circle" : "cancel";
    statusIcon.classList.toggle("text-secondary", Boolean(included));
    statusIcon.classList.toggle("text-error", !included);
    const iconContainer = card.querySelector(".material-symbols-outlined")?.parentElement;
    iconContainer?.classList.toggle("bg-secondary-container", Boolean(included));
    iconContainer?.classList.toggle("text-secondary", Boolean(included));
    iconContainer?.classList.toggle("bg-surface-container-high", !included);
    iconContainer?.classList.toggle("text-outline", !included);
    card.classList.toggle("opacity-85", !included);
  });

  const directionsLink = document.querySelector('aside a[href^="https://www.google.com/maps/dir/"]');
  if (directionsLink) {
    const destination = encodeURIComponent(`${address}, Philippines`);
    directionsLink.href = `https://www.google.com/maps/dir/?api=1&destination=${destination}`;
  }

  const callLink = document.querySelector('aside a[href^="tel:"]');
  const smsLink = document.querySelector('aside a[href^="sms:"]');
  if (dorm.landlordPhone) {
    const phoneUri = dorm.landlordPhone.replace(/[^+0-9]/g, "");
    if (callLink) callLink.href = `tel:${phoneUri}`;
    if (smsLink) smsLink.href = `sms:${phoneUri}`;
  } else {
    if (callLink) callLink.hidden = true;
    if (smsLink) smsLink.hidden = true;
  }
})();
