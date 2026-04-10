(() => {
  "use strict";

  let hoveredVideoUrl = null;
  let hoveredElement = null;
  let lastClientX = -1;
  let lastClientY = -1;

  function refreshHoverFromLastPointer() {
    if (lastClientX < 0 || lastClientY < 0) return;
    const el = document.elementFromPoint(lastClientX, lastClientY);
    if (!el) return;
    const result = findVideoAnchor(el);
    if (result) {
      hoveredVideoUrl = result.url;
      hoveredElement = result.anchor;
    }
  }

  /**
   * Extract a clean YouTube video URL from an anchor element's href.
   * Handles /watch?v=ID and /shorts/ID formats.
   * Returns null if no video ID is found.
   */
  function extractVideoUrl(href) {
    try {
      const url = new URL(href, location.origin);

      // Standard watch URL
      const videoId = url.searchParams.get("v");
      if (videoId) {
        return `https://www.youtube.com/watch?v=${videoId}`;
      }

      // Shorts URL: /shorts/VIDEO_ID
      const shortsMatch = url.pathname.match(/^\/shorts\/([a-zA-Z0-9_-]+)/);
      if (shortsMatch) {
        return `https://www.youtube.com/watch?v=${shortsMatch[1]}`;
      }
    } catch {
      // ignore malformed URLs
    }
    return null;
  }

  /**
   * Walk up the DOM from an element to find the closest <a> with a video href.
   * If the direct ancestor walk fails (e.g. YouTube's hover preview overlay is
   * a sibling of the <a>, not a child), fall back to finding the nearest
   * renderer/thumbnail container and searching within it.
   */
  function findVideoAnchor(el) {
    let current = el;
    let depth = 0;
    let container = null;

    while (current && depth < 20) {
      // Direct ancestor match
      if (current.tagName === "A" && current.href) {
        const clean = extractVideoUrl(current.href);
        if (clean) return { anchor: current, url: clean };
      }

      // Remember the closest thumbnail/renderer container for fallback
      if (!container) {
        const tag = current.tagName?.toLowerCase() || "";
        if (
          tag === "ytd-thumbnail" ||
          tag === "ytd-rich-item-renderer" ||
          tag === "ytd-compact-video-renderer" ||
          tag === "ytd-grid-video-renderer" ||
          tag === "ytd-video-renderer" ||
          tag === "ytd-rich-grid-media" ||
          tag === "ytd-playlist-video-renderer"
        ) {
          container = current;
        }
      }

      current = current.parentElement;
      depth++;
    }

    // Fallback: search within the container for a video link
    if (container) {
      const link = container.querySelector(
        'a#thumbnail[href], a[href*="/watch?v="], a[href*="/shorts/"]'
      );
      if (link && link.href) {
        const clean = extractVideoUrl(link.href);
        if (clean) return { anchor: link, url: clean };
      }
    }

    return null;
  }

  // --- Hover tracking via event delegation on document ---

  document.addEventListener(
    "pointermove",
    (e) => {
      lastClientX = e.clientX;
      lastClientY = e.clientY;
    },
    true
  );

  document.addEventListener(
    "mouseover",
    (e) => {
      const result = findVideoAnchor(e.target);
      if (result) {
        hoveredVideoUrl = result.url;
        hoveredElement = result.anchor;
      }
    },
    true
  );

  document.addEventListener(
    "mousemove",
    (e) => {
      const result = findVideoAnchor(e.target);
      if (result) {
        hoveredVideoUrl = result.url;
        hoveredElement = result.anchor;
      }
    },
    true
  );

  window.addEventListener("focus", () => {
    requestAnimationFrame(() => refreshHoverFromLastPointer());
  });

  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible")
      requestAnimationFrame(() => refreshHoverFromLastPointer());
  });

  document.addEventListener(
    "mouseout",
    (e) => {
      // Only clear if we're leaving the tracked anchor (or its children)
      if (hoveredElement && !hoveredElement.contains(e.relatedTarget)) {
        hoveredVideoUrl = null;
        hoveredElement = null;
      }
    },
    true
  );

  // Alt+X: used by copy.ahk (SendEvent) after it focuses YouTube — not a separate global shortcut.

  document.addEventListener(
    "keydown",
    (e) => {
      if (e.altKey && (e.key === "x" || e.key === "X") && !e.ctrlKey && !e.metaKey && !e.shiftKey) {
        if (!hoveredVideoUrl) return;

        e.preventDefault();
        e.stopPropagation();

        navigator.clipboard.writeText(hoveredVideoUrl).then(() => {
          showToast(hoveredElement, "Copied!");
        }).catch(() => {
          // Fallback: use execCommand for older contexts / when clipboard API is blocked
          fallbackCopy(hoveredVideoUrl);
          showToast(hoveredElement, "Copied!");
        });
      }
    },
    true
  );

  /**
   * Fallback copy using a temporary textarea + document.execCommand.
   */
  function fallbackCopy(text) {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.left = "-9999px";
    document.body.appendChild(ta);
    ta.select();
    document.execCommand("copy");
    ta.remove();
  }

  /**
   * Show a small "Copied!" toast near the hovered element.
   */
  function showToast(anchor, message) {
    // Remove any existing toast first
    const existing = document.getElementById("copyurl-toast");
    if (existing) existing.remove();

    const toast = document.createElement("div");
    toast.id = "copyurl-toast";
    toast.textContent = message;
    Object.assign(toast.style, {
      position: "fixed",
      zIndex: "2147483647",
      background: "#323232",
      color: "#fff",
      padding: "6px 14px",
      borderRadius: "6px",
      fontSize: "13px",
      fontFamily: "Roboto, Arial, sans-serif",
      fontWeight: "500",
      boxShadow: "0 2px 8px rgba(0,0,0,.35)",
      pointerEvents: "none",
      opacity: "0",
      transition: "opacity 0.2s ease",
    });

    document.body.appendChild(toast);

    // Position near the anchor element
    if (anchor) {
      const rect = anchor.getBoundingClientRect();
      toast.style.top = `${rect.top - toast.offsetHeight - 8}px`;
      toast.style.left = `${rect.left + rect.width / 2 - toast.offsetWidth / 2}px`;

      // Clamp to viewport
      const toastRect = toast.getBoundingClientRect();
      if (toastRect.left < 8) toast.style.left = "8px";
      if (toastRect.right > window.innerWidth - 8)
        toast.style.left = `${window.innerWidth - toast.offsetWidth - 8}px`;
      if (toastRect.top < 8) toast.style.top = `${rect.bottom + 8}px`;
    } else {
      toast.style.bottom = "24px";
      toast.style.left = "50%";
      toast.style.transform = "translateX(-50%)";
    }

    // Fade in
    requestAnimationFrame(() => {
      toast.style.opacity = "1";
    });

    // Fade out and remove after 1.5s
    setTimeout(() => {
      toast.style.opacity = "0";
      setTimeout(() => toast.remove(), 250);
    }, 1500);
  }
})();
