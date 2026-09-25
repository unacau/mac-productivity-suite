/**
 * Xomsky — Three Design Variants & Interactive Verification Engine (variants.js)
 * Implements:
 * 1. Variant Switching:
 *    - Option A: 3D WebGL Masterpiece (Native Three.js 3D Mac Window, 60fps parallax)
 *    - Option B: Animos 60fps Flow (Focus Slider & Cover Flow carousel, zero blur lag)
 *    - Option C: Full-Bleed 60fps Video + Reactive Companion Mascot
 * 2. Hardware-accelerated 60fps Animos Carousel (Focus Slider & Cover Flow modes)
 * 3. Reactive Mascot Companion for Option C (real-time HUD toasts & squish physics)
 * 4. Linux Copy-on-Select Live Toast Engine
 * 5. Full keyboard and URL navigation (#option-a, #option-b, #option-c)
 */

(function () {
  "use strict";

  // --- Audio Synthesis for Tactile Feedback ---
  let audioCtx = null;
  function getAudioContext() {
    if (!audioCtx) {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (AudioContext) audioCtx = new AudioContext();
    }
    if (audioCtx && audioCtx.state === "suspended") {
      audioCtx.resume();
    }
    return audioCtx;
  }

  function playTactileClick(type = "soft") {
    try {
      const ctx = getAudioContext();
      if (!ctx) return;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain);
      gain.connect(ctx.destination);

      const now = ctx.currentTime;
      if (type === "copy") {
        osc.type = "sine";
        osc.frequency.setValueAtTime(880, now);
        osc.frequency.exponentialRampToValueAtTime(1320, now + 0.04);
        gain.gain.setValueAtTime(0.08, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.06);
        osc.start(now);
        osc.stop(now + 0.06);
      } else if (type === "popover") {
        osc.type = "triangle";
        osc.frequency.setValueAtTime(440, now);
        osc.frequency.exponentialRampToValueAtTime(660, now + 0.05);
        gain.gain.setValueAtTime(0.06, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
        osc.start(now);
        osc.stop(now + 0.05);
      } else {
        osc.type = "sine";
        osc.frequency.setValueAtTime(320, now);
        osc.frequency.exponentialRampToValueAtTime(180, now + 0.03);
        gain.gain.setValueAtTime(0.12, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
        osc.start(now);
        osc.stop(now + 0.04);
      }
    } catch (e) {}
  }

  // --- Live Copy-on-Select Toast Engine ---
  let copyToastEl = null;
  let copyToastTimeout = null;

  function initCopyToast() {
    copyToastEl = document.createElement("div");
    copyToastEl.className = "xomsky-copy-toast";
    copyToastEl.innerHTML = `<span class="toast-check">✓</span> <span class="toast-text">Copied to Clipboard</span>`;
    document.body.appendChild(copyToastEl);

    document.addEventListener("mouseup", handleTextSelection);
    document.addEventListener("keyup", (e) => {
      if (e.key === "Shift" || e.key === "ArrowLeft" || e.key === "ArrowRight") {
        handleTextSelection(e);
      }
    });
  }

  function handleTextSelection(e) {
    const sel = window.getSelection();
    if (!sel || sel.isCollapsed) return;

    const text = sel.toString().trim();
    if (text.length < 2) return;

    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).catch(() => {});
      }
    } catch (err) {}

    playTactileClick("copy");

    let x = e.clientX;
    let y = e.clientY;

    if (!x || !y) {
      try {
        const range = sel.getRangeAt(0);
        const rect = range.getBoundingClientRect();
        x = rect.left + rect.width / 2;
        y = rect.top - 10;
      } catch (err) {
        x = window.innerWidth / 2;
        y = window.innerHeight / 2;
      }
    }

    showCopyToast(x, y, text);
    handleMascotReaction("copy", 0, "select");
  }

  function showCopyToast(x, y, text) {
    if (!copyToastEl) return;
    if (copyToastTimeout) clearTimeout(copyToastTimeout);

    const toastW = 140;
    const toastH = 34;
    const posX = Math.max(16, Math.min(window.innerWidth - toastW - 16, x - toastW / 2));
    const posY = Math.max(16, y - toastH - 12);

    copyToastEl.style.left = `${posX}px`;
    copyToastEl.style.top = `${posY}px`;
    copyToastEl.classList.add("visible");

    copyToastTimeout = setTimeout(() => {
      copyToastEl.classList.remove("visible");
    }, 1100);
  }

  // --- Variant Switching Engine ---
  const VARIANTS = {
    "option-c": {
      name: "🎬 Flagship · 60fps Video & Live Mascot",
      desc: "Authentic 60fps macOS screen recordings with reactive companion mascot and Pocket Mac controls"
    },
    "option-a": {
      name: "🗄️ Archive A · 3D WebGL HUD",
      desc: "Archived exploration: Native Three.js 3D floating Mac window with 60fps spatial parallax"
    },
    "option-b": {
      name: "🗄️ Archive B · 60fps Flow Deck",
      desc: "Archived exploration: Animos-inspired Focus Slider & Cover Flow carousel"
    },
    "original": {
      name: "🗄️ Archive 0 · Baseline Cockpit",
      desc: "Archived exploration: Original 5-key cockpit selector widget"
    }
  };

  let currentVariant = "option-c";

  function normalizeVariantId(id) {
    if (!id) return "option-c";
    const lower = id.toLowerCase().trim();
    if (lower === "c" || lower === "option-c" || lower === "video" || lower === "flagship" || lower === "main") return "option-c";
    if (lower === "a" || lower === "option-a" || lower === "hybrid") return "option-a";
    if (lower === "b" || lower === "option-b") return "option-b";
    if (lower === "original" || lower === "0") return "original";
    return VARIANTS[lower] ? lower : "option-c";
  }

  function switchVariant(variantId, updateUrl = true) {
    const targetVariant = normalizeVariantId(variantId);
    currentVariant = targetVariant;

    // Update root dataset attribute
    document.documentElement.setAttribute("data-design-variant", targetVariant);

    // Update active pill in switcher dock
    document.querySelectorAll(".variant-pill-btn").forEach((btn) => {
      const v = normalizeVariantId(btn.getAttribute("data-variant"));
      btn.classList.toggle("active", v === targetVariant);
    });

    // Toggle stage sections
    document.querySelectorAll(".variant-stage-section").forEach((sec) => {
      const secVar = normalizeVariantId(sec.getAttribute("data-variant-section"));
      sec.style.display = secVar === targetVariant ? "block" : "none";
    });

    // Notify Three.js 3D Scene
    if (targetVariant === "option-a") {
      if (typeof window.setOptionAWindowsVisible === "function") {
        window.setOptionAWindowsVisible(true);
      }
      if (typeof window.setCameraView === "function") {
        window.setCameraView("optionA");
      }
    } else if (targetVariant === "option-b") {
      if (typeof window.setOptionAWindowsVisible === "function") {
        window.setOptionAWindowsVisible(false);
      }
      if (typeof window.setCameraView === "function") {
        window.setCameraView("optionB");
      }
    } else if (targetVariant === "option-c") {
      if (typeof window.setOptionAWindowsVisible === "function") {
        window.setOptionAWindowsVisible(false);
      }
      if (typeof window.setCameraView === "function") {
        window.setCameraView("optionC");
      }
    } else {
      if (typeof window.setOptionAWindowsVisible === "function") {
        window.setOptionAWindowsVisible(false);
      }
      if (typeof window.setCameraView === "function") {
        window.setCameraView("hero");
      }
    }

    // Update lighting preset in Three.js
    if (typeof window.setLightingPreset === "function") {
      window.setLightingPreset(targetVariant);
    }

    // Play/Pause Option C Background Video
    const optCVideo = document.getElementById("cinematic-bg-video");
    if (optCVideo) {
      if (targetVariant === "option-c") {
        optCVideo.play().catch(() => {});
      } else {
        optCVideo.pause();
      }
    }

    // Save to localStorage
    try {
      localStorage.setItem("xomsky_design_variant", targetVariant);
    } catch (e) {}

    // Update URL hash
    if (updateUrl && history.replaceState) {
      history.replaceState(null, "", `#${targetVariant}`);
    }

    playTactileClick("soft");
  }

  // --- Option A: 3D HUD Dock Bar Handlers ---
  function initOptionAControls() {
    const dock = document.getElementById("option-a-dock-bar") || document.querySelector(".option-a-dock-bar, .option-a-quick-bar");
    if (!dock) return;

    const profileBtns = dock.querySelectorAll(".quick-pill-btn[data-profile-idx]");
    const appBtns = dock.querySelectorAll(".app-pill-btn[data-app]");

    profileBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const idx = parseInt(btn.getAttribute("data-profile-idx"), 10);
        dock.querySelectorAll(".quick-pill-btn").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        if (typeof window.activateCategory === "function") {
          window.activateCategory("chrome", idx, String(idx + 1), true);
        }
      });
    });

    appBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const app = btn.getAttribute("data-app");
        dock.querySelectorAll(".quick-pill-btn").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");

        if (app === "terminal") {
          if (typeof window.activateCategory === "function") {
            window.activateCategory("terminal", 0, "t", true);
          }
          handleMascotReaction("terminal", 0, "t");
        } else if (app === "ide") {
          if (typeof window.activateCategory === "function") {
            window.activateCategory("ide", 0, "i", true);
          }
          handleMascotReaction("ide", 0, "i");
        } else if (app === "ai") {
          if (typeof window.activateCategory === "function") {
            window.activateCategory("ai", 0, "a", true);
          }
          handleMascotReaction("ai", 0, "a");
        } else if (app === "notes") {
          if (typeof window.activateCategory === "function") {
            window.activateCategory("notes", 0, "n", true);
          }
          handleMascotReaction("notes", 0, "n");
        } else if (app === "copy") {
          const rect = btn.getBoundingClientRect();
          showCopyToast(rect.left + rect.width / 2, rect.top - 10, "Highlight any text on your Mac — it's already copied");
          handleMascotReaction("copy", 0, "select");
          if (typeof window.triggerHamsterSquish === "function") {
            window.triggerHamsterSquish();
          }
        }
      });
    });
  }

  function updateCategoryState(category, index = 0, keyId = null) {
    if (category === "chrome") {
      const idx = parseInt(index, 10) || 0;
      // Option A Quick Pills
      document.querySelectorAll(".option-a-dock-bar .quick-pill-btn[data-profile-idx], .option-a-quick-bar .quick-pill-btn[data-profile-idx]").forEach((btn) => {
        const pIdx = parseInt(btn.getAttribute("data-profile-idx"), 10);
        btn.classList.toggle("active", pIdx === idx);
      });
      document.querySelectorAll(".option-a-dock-bar .app-pill-btn").forEach((btn) => {
        btn.classList.remove("active");
      });
      // Option B Deck Profile Items
      document.querySelectorAll(".deck-profile-item").forEach((item) => {
        const pIdx = parseInt(item.getAttribute("data-index"), 10);
        item.classList.toggle("active", pIdx === idx);
      });
    } else {
      // Option A App Pills
      document.querySelectorAll(".option-a-dock-bar .quick-pill-btn[data-profile-idx]").forEach((btn) => {
        btn.classList.remove("active");
      });
      document.querySelectorAll(".option-a-dock-bar .app-pill-btn").forEach((btn) => {
        btn.classList.toggle("active", btn.getAttribute("data-app") === category);
      });

      const appMap = { finder: "f", terminal: "t", ide: "i", ai: "a", settings: "s", chrome: "c", notes: "n" };
      const targetApp = appMap[category] || keyId;
      if (targetApp) {
        document.querySelectorAll(".deck-app-pill").forEach((pill) => {
          pill.classList.toggle("active", pill.getAttribute("data-app") === targetApp);
        });
      }
    }
  }

  // --- Option B: Animos 60fps Flow (Focus Slider & Cover Flow) ---
  let currentDeckIndex = 0;
  let isDeckHovered = false;
  let animosAutoTimer = null;
  let flowMode = "focus"; // "focus" or "coverflow"
  let lastWheelTime = 0;

  function initAnimosCarousel() {
    const viewport = document.getElementById("animos-viewport");
    if (!viewport) return;

    const cards = viewport.querySelectorAll(".deck-card");
    const pills = document.querySelectorAll(".deck-indicator-pills .deck-pill");
    const modeBtns = document.querySelectorAll(".animos-mode-btn");
    const copyBox = document.getElementById("deck-selectable-box");
    const copyStatus = document.getElementById("deck-copy-status-line");

    function setFlowMode(newMode) {
      flowMode = newMode;
      modeBtns.forEach(btn => {
        btn.classList.toggle("active", btn.getAttribute("data-flow-mode") === newMode);
      });
      viewport.classList.remove("mode-focus", "mode-coverflow");
      viewport.classList.add(`mode-${newMode}`);
      playTactileClick("soft");
    }

    modeBtns.forEach(btn => {
      btn.addEventListener("click", () => {
        setFlowMode(btn.getAttribute("data-flow-mode"));
      });
    });

    function setDeckIndex(index, fromUser = false) {
      currentDeckIndex = (index % cards.length + cards.length) % cards.length;

      cards.forEach((card, i) => {
        card.classList.remove("card-active", "card-prev", "card-next", "card-hidden");
        if (i === currentDeckIndex) {
          card.classList.add("card-active");
        } else if (i === (currentDeckIndex - 1 + cards.length) % cards.length) {
          card.classList.add("card-prev");
        } else if (i === (currentDeckIndex + 1) % cards.length) {
          card.classList.add("card-next");
        } else {
          card.classList.add("card-hidden");
        }
      });

      pills.forEach((pill) => {
        const pIdx = parseInt(pill.getAttribute("data-deck-index"), 10);
        pill.classList.toggle("active", pIdx === currentDeckIndex);
      });

      if (fromUser) playTactileClick("soft");

      // Sync 3D keyboard in background
      if (typeof window.activateCategory === "function") {
        if (currentDeckIndex === 0) {
          window.activateCategory("chrome", 0, "c", false);
        } else if (currentDeckIndex === 1) {
          window.activateCategory("terminal", 0, "t", false);
        } else if (currentDeckIndex === 2) {
          if (typeof window.triggerHamsterSquish === "function") {
            window.triggerHamsterSquish();
          }
        }
      }
    }

    // Pill clicks
    pills.forEach((pill) => {
      pill.addEventListener("click", () => {
        const idx = parseInt(pill.getAttribute("data-deck-index"), 10);
        setDeckIndex(idx, true);
      });
    });

    // Card clicks
    cards.forEach((card) => {
      card.addEventListener("click", (e) => {
        if (card.classList.contains("card-prev")) {
          e.stopPropagation();
          setDeckIndex(currentDeckIndex - 1, true);
        } else if (card.classList.contains("card-next")) {
          e.stopPropagation();
          setDeckIndex(currentDeckIndex + 1, true);
        }
      });
    });

    // Throttled 60fps Mouse Wheel with Hardware Acceleration
    viewport.addEventListener("wheel", (e) => {
      e.preventDefault();
      const now = performance.now();
      if (now - lastWheelTime < 260) return;

      if (Math.abs(e.deltaY) > 20 || Math.abs(e.deltaX) > 20) {
        lastWheelTime = now;
        const delta = Math.abs(e.deltaY) > Math.abs(e.deltaX) ? e.deltaY : e.deltaX;
        setDeckIndex(delta > 0 ? currentDeckIndex + 1 : currentDeckIndex - 1, true);
      }
    }, { passive: false });

    // Touch Swipe
    let touchStartX = 0;
    let touchStartY = 0;
    viewport.addEventListener("touchstart", (e) => {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
    }, { passive: true });

    viewport.addEventListener("touchend", (e) => {
      const diffX = touchStartX - e.changedTouches[0].clientX;
      const diffY = touchStartY - e.changedTouches[0].clientY;
      const mainDiff = Math.abs(diffX) > Math.abs(diffY) ? diffX : diffY;
      if (Math.abs(mainDiff) > 30) {
        setDeckIndex(mainDiff > 0 ? currentDeckIndex + 1 : currentDeckIndex - 1, true);
      }
    }, { passive: true });

    // Arrow keys
    window.addEventListener("keydown", (e) => {
      if (currentVariant !== "option-b") return;
      if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") return;
      if (e.key === "ArrowRight" || e.key === "ArrowDown") {
        setDeckIndex(currentDeckIndex + 1, true);
      } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
        setDeckIndex(currentDeckIndex - 1, true);
      }
    });

    // Auto-cycle: zero idle CPU spikes, pauses when tab is backgrounded
    function startAutoCycle() {
      if (animosAutoTimer) clearInterval(animosAutoTimer);
      animosAutoTimer = setInterval(() => {
        if (!isDeckHovered && currentVariant === "option-b" && document.visibilityState === "visible") {
          setDeckIndex(currentDeckIndex + 1, false);
        }
      }, 4500);
    }

    viewport.addEventListener("mouseenter", () => { isDeckHovered = true; });
    viewport.addEventListener("mouseleave", () => { isDeckHovered = false; });
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState !== "visible") {
        isDeckHovered = true;
      } else {
        isDeckHovered = false;
      }
    });
    startAutoCycle();

    // Card 0 Profile Item Clicks
    document.querySelectorAll(".deck-profile-item").forEach((item) => {
      item.addEventListener("click", (e) => {
        e.stopPropagation();
        document.querySelectorAll(".deck-profile-item").forEach(p => p.classList.remove("active"));
        item.classList.add("active");
        const idx = parseInt(item.getAttribute("data-index"), 10);
        if (typeof window.activateCategory === "function") {
          window.activateCategory("chrome", idx, String(idx + 1), true);
        }
        playTactileClick("soft");
      });
    });

    // Card 1 App Pill Clicks
    document.querySelectorAll(".deck-app-pill").forEach((pill) => {
      pill.addEventListener("click", (e) => {
        e.stopPropagation();
        document.querySelectorAll(".deck-app-pill").forEach(p => p.classList.remove("active"));
        pill.classList.add("active");
        const appKey = pill.getAttribute("data-app");
        const catMap = { f: "finder", t: "terminal", s: "settings", c: "chrome" };
        const cat = catMap[appKey] || "finder";
        if (typeof window.activateCategory === "function") {
          window.activateCategory(cat, 0, appKey, true);
        }
        playTactileClick("soft");
      });
    });

    // Card 2 Copy Sandbox
    if (copyBox) {
      function triggerCopyText(e) {
        const text = "Highlight any text on your Mac — it's already in your clipboard.";
        try {
          if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).catch(() => {});
          }
        } catch (err) {}

        playTactileClick("copy");

        const rect = copyBox.getBoundingClientRect();
        const x = e.clientX || (rect.left + rect.width / 2);
        const y = e.clientY || (rect.top - 10);
        showCopyToast(x, y, text);

        if (copyStatus) {
          copyStatus.innerHTML = `<span style="color:#10B981">✓ Copied directly to clipboard!</span>`;
          setTimeout(() => {
            copyStatus.innerHTML = `<span class="copy-pulse-indicator">●</span> Drag cursor over text above`;
          }, 2400);
        }
      }

      copyBox.addEventListener("mouseup", triggerCopyText);
      copyBox.addEventListener("click", triggerCopyText);
    }

    setDeckIndex(0, false);
    setFlowMode("focus");
  }

  // --- Option C: Full-Bleed 60fps Video & Reactive Companion Mascot ---
  function initOptionCControls() {
    const videoEl = document.getElementById("cinematic-bg-video");
    const tabs = document.querySelectorAll(".cinematic-video-tabs .cinematic-tab-btn");
    const macroBtns = document.querySelectorAll(".cinematic-macro-strip .macro-tap-btn");
    const companionWidget = document.getElementById("companion-hud-widget");
    const companionAvatar = document.getElementById("companion-avatar");
    const mobileSpacer = document.getElementById("option-c-mobile-spacer");

    // Video Tabs
    tabs.forEach((tab) => {
      tab.addEventListener("click", () => {
        tabs.forEach(t => t.classList.remove("active"));
        tab.classList.add("active");
        const src = tab.getAttribute("data-video-src");
        if (videoEl && src) {
          videoEl.src = src;
          videoEl.load();
          videoEl.play().catch(() => {});
          playTactileClick("popover");
        }
      });
    });

    // Macro Hotkey Simulator with Video Scrub & Mobile Haptics
    macroBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const key = btn.getAttribute("data-key");
        const seekTime = btn.getAttribute("data-seek");
        playTactileClick("soft");
        if (navigator.vibrate) navigator.vibrate(15);

        // Highlight active button briefly
        macroBtns.forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        setTimeout(() => btn.classList.remove("active"), 800);

        if (key === "c") {
          if (videoEl && seekTime) {
            ensureVideoTrack("assets/media/screenrec-switch-app.mp4", parseFloat(seekTime));
          }
          if (typeof window.activateCategory === "function") {
            window.activateCategory("chrome", 0, "c", true);
          }
          handleMascotReaction("chrome", 0, "c");
        } else if (key === "1") {
          if (videoEl && seekTime) {
            ensureVideoTrack("assets/media/screenrec-switch-app.mp4", parseFloat(seekTime));
          }
          if (typeof window.activateCategory === "function") {
            window.activateCategory("chrome", 0, "1", true);
          }
          handleMascotReaction("chrome", 0, "1");
        } else if (key === "2") {
          if (videoEl && seekTime) {
            ensureVideoTrack("assets/media/screenrec-switch-app.mp4", parseFloat(seekTime));
          }
          if (typeof window.activateCategory === "function") {
            window.activateCategory("chrome", 1, "2", true);
          }
          handleMascotReaction("chrome", 1, "2");
        } else if (key === "t") {
          if (videoEl && seekTime) {
            ensureVideoTrack("assets/media/screenrec-switch-app.mp4", parseFloat(seekTime));
          }
          if (typeof window.activateCategory === "function") {
            window.activateCategory("terminal", 0, "t", true);
          }
          handleMascotReaction("terminal", 0, "t");
        } else if (key === "copy") {
          ensureVideoTrack("assets/media/screenrec-select-copy.mp4", 0);
          const text = "Instant copy-on-select demo";
          showCopyToast(window.innerWidth / 2, window.innerHeight / 2, text);
          handleMascotReaction("copy", 0, "select");
        }
      });
    });

    function ensureVideoTrack(targetSrc, seekTime = 0) {
      if (!videoEl) return;
      const currentSrc = videoEl.getAttribute("src") || (videoEl.querySelector("source") ? videoEl.querySelector("source").getAttribute("src") : "");
      if (!currentSrc.includes(targetSrc)) {
        videoEl.src = targetSrc;
        videoEl.load();
      }
      videoEl.currentTime = seekTime;
      videoEl.play().catch(() => {});
      
      // Update tab active states
      tabs.forEach((tab) => {
        const tSrc = tab.getAttribute("data-video-src");
        tab.classList.toggle("active", tSrc === targetSrc);
      });
    }

    // Companion Widget & Avatar Click (Squish Physics)
    function triggerCompanionSquish(e) {
      if (e) e.stopPropagation();
      if (navigator.vibrate) navigator.vibrate([20, 40]);
      if (typeof window.triggerHamsterSquish === "function") {
        window.triggerHamsterSquish();
      }
      playTactileClick("copy");
      handleMascotReaction("companion", 0, "click");
    }

    if (companionWidget) {
      companionWidget.addEventListener("click", triggerCompanionSquish);
    }
    if (companionAvatar) {
      companionAvatar.addEventListener("click", triggerCompanionSquish);
    }
    if (mobileSpacer) {
      mobileSpacer.addEventListener("click", triggerCompanionSquish);
    }

    // AirDrop & Web Share API Handlers ("Send to My Mac")
    const airdropBtns = document.querySelectorAll(".airdrop-share-btn, #mobile-sticky-airdrop");
    airdropBtns.forEach((btn) => {
      btn.addEventListener("click", (e) => {
        if (e) e.preventDefault();
        playTactileClick("popover");
        if (navigator.vibrate) navigator.vibrate([15, 30]);

        if (navigator.share) {
          navigator.share({
            title: "Xomsky — Native macOS Productivity Suite",
            text: "Instant Chrome & Brave profile switching and copy-on-select for Mac: brew install unacau/tap/xomsky",
            url: "https://xomsky.app"
          }).catch(() => {});
        } else {
          const text = "brew install unacau/tap/xomsky";
          try {
            if (navigator.clipboard && navigator.clipboard.writeText) {
              navigator.clipboard.writeText(text).catch(() => {});
            }
          } catch (err) {}
          showCopyToast(window.innerWidth / 2, window.innerHeight / 2, "Copied brew command to clipboard!");
        }
      });
    });

    // Mobile Copy-on-Select Touch Sandbox
    const copySandbox = document.getElementById("mobile-copy-sandbox");
    if (copySandbox) {
      copySandbox.addEventListener("mouseup", (e) => {
        const sel = window.getSelection();
        if (sel && !sel.isCollapsed && sel.toString().trim().length > 1) {
          const rect = copySandbox.getBoundingClientRect();
          showCopyToast(rect.left + rect.width / 2, rect.top - 12, sel.toString().trim());
        }
      });
    }

    // Sticky Mobile Bottom Bar Visibility on Scroll
    const stickyBar = document.getElementById("mobile-sticky-bar");
    if (stickyBar) {
      window.addEventListener("scroll", () => {
        if (window.innerWidth <= 900) {
          const show = window.scrollY > 200;
          stickyBar.classList.toggle("visible", show);
        } else {
          stickyBar.classList.remove("visible");
        }
      }, { passive: true });
    }
  }

  // Reactive Companion Mascot Reactions
  function handleMascotReaction(category, index, keyId) {
    const speech = document.getElementById("companion-speech");
    const widget = document.getElementById("companion-hud-widget");
    const avatar = document.getElementById("companion-avatar");

    if (widget) {
      widget.classList.remove("companion-bounce");
      void widget.offsetWidth;
      widget.classList.add("companion-bounce");
      setTimeout(() => widget.classList.remove("companion-bounce"), 450);
    }

    if (avatar) {
      avatar.classList.remove("companion-squish");
      void avatar.offsetWidth;
      avatar.classList.add("companion-squish");
      setTimeout(() => avatar.classList.remove("companion-squish"), 400);
    }

    if (!speech) return;

    let msg = "⚡ 0ms Latency Response!";
    if (category === "chrome") {
      const names = ["Personal (Igor)", "Work (Al11)", "GCP Free Trial", "Team"];
      const targetName = names[index] || "Profile";
      msg = `⚡ Teleported to Space ${index + 1} (${targetName}) in 0ms!`;
    } else if (category === "terminal") {
      msg = `💻 Raised Terminal in 0ms! (Caps + T)`;
    } else if (category === "ide") {
      msg = `🛠️ Focused IDE Workspace in 0ms! (Caps + I)`;
    } else if (category === "ai") {
      msg = `🤖 Antigravity AI Agent ready! (Caps + A)`;
    } else if (category === "notes") {
      msg = `📝 Opened Notes scratchpad in 0ms! (Caps + N)`;
    } else if (category === "copy") {
      msg = `📋 Text copied directly to clipboard!`;
    } else if (category === "companion") {
      msg = `🐹 Squeeeak! 100% native Swift 6.`;
    }

    speech.textContent = msg;
    speech.classList.remove("active");
    void speech.offsetWidth;
    speech.classList.add("active");
  }

  // --- Authentic 60fps Video Proofs Modal ---
  function initProofsModal() {
    const openBtn = document.querySelector(".open-proofs-btn");
    const modal = document.getElementById("proofs-modal");
    const closeBtn = document.getElementById("proofs-close-btn");
    const modalVideo = document.getElementById("proofs-video");
    const tabs = document.querySelectorAll(".proofs-tab-btn");

    if (!modal) return;

    function openModal(videoSrc) {
      modal.classList.add("active");
      if (modalVideo) {
        if (videoSrc) modalVideo.src = videoSrc;
        modalVideo.currentTime = 0;
        modalVideo.load();
        modalVideo.play().catch(() => {});
      }
      playTactileClick("popover");
    }

    function closeModal() {
      modal.classList.remove("active");
      if (modalVideo) {
        modalVideo.pause();
      }
      playTactileClick("soft");
    }

    if (openBtn) {
      openBtn.addEventListener("click", () => {
        const src = openBtn.getAttribute("data-video-src") || "assets/media/screenrec-switch-app.mp4";
        openModal(src);
      });
    }

    if (closeBtn) {
      closeBtn.addEventListener("click", closeModal);
    }

    modal.addEventListener("click", (e) => {
      if (e.target === modal) {
        closeModal();
      }
    });

    window.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && modal.classList.contains("active")) {
        closeModal();
      }
    });

    tabs.forEach((tab) => {
      tab.addEventListener("click", () => {
        tabs.forEach(t => t.classList.remove("active"));
        tab.classList.add("active");
        const src = tab.getAttribute("data-src");
        if (modalVideo && src) {
          modalVideo.src = src;
          modalVideo.currentTime = 0;
          modalVideo.load();
          modalVideo.play().catch(() => {});
          playTactileClick("popover");
        }
      });
    });
  }

  // --- Brew Install Strip Copy Across Variants ---
  function initInstallStrips() {
    document.querySelectorAll(".hero-install-strip, .terminal-install-bar").forEach((strip) => {
      strip.addEventListener("click", (e) => {
        const cmdEl = strip.querySelector(".hero-install-cmd, .terminal-cmd");
        const text = cmdEl ? cmdEl.textContent.trim() : "brew install unacau/tap/xomsky";

        try {
          if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).catch(() => {});
          }
        } catch (err) {}

        playTactileClick("copy");

        const rect = strip.getBoundingClientRect();
        const x = e.clientX || (rect.left + rect.width / 2);
        const y = e.clientY || (rect.top - 10);
        showCopyToast(x, y, text);

        const btn = strip.querySelector(".hero-install-copy-btn, .copy-cmd-btn");
        if (btn) {
          const origHtml = btn.innerHTML;
          btn.innerHTML = `<span>✓</span> <span>Copied!</span>`;
          btn.style.color = "#10B981";
          setTimeout(() => {
            btn.innerHTML = origHtml;
            btn.style.color = "";
          }, 1400);
        }
      });
    });
  }

  // --- Initialization Lifecycle ---
  document.addEventListener("DOMContentLoaded", () => {
    initCopyToast();
    initOptionCControls();
    initProofsModal();
    initInstallStrips();

    // Check if running in Multi-Variant Archive mode (presence of switcher dock)
    const switcherBar = document.getElementById("variant-switcher-bar");
    if (switcherBar) {
      initOptionAControls();
      initAnimosCarousel();

      // Determine target variant from URL query > URL hash > localStorage > default
      const params = new URLSearchParams(window.location.search);
      const queryV = params.get("variant");
      const hashV = window.location.hash.replace("#", "");
      let savedV = null;
      try {
        savedV = localStorage.getItem("xomsky_design_variant");
      } catch (e) {}

      const defaultAttr = document.documentElement.getAttribute("data-default-variant") || "option-c";
      const candidate = queryV || hashV || savedV || defaultAttr;
      const targetVariant = normalizeVariantId(candidate);
      switchVariant(targetVariant, false);

      // Pill click handlers in switcher dock
      document.querySelectorAll(".variant-pill-btn").forEach((btn) => {
        btn.addEventListener("click", () => {
          const v = btn.getAttribute("data-variant");
          switchVariant(v, true);
        });
      });

      // Minimize / Expand Toggle for Switcher Dock
      const switcherToggle = document.getElementById("variant-switcher-toggle");
      const switcherMini = document.querySelector(".switcher-mini-label");

      if (switcherToggle) {
        switcherToggle.addEventListener("click", (e) => {
          e.stopPropagation();
          switcherBar.classList.toggle("minimized");
          switcherToggle.textContent = switcherBar.classList.contains("minimized") ? "+" : "−";
        });
      }
      if (switcherMini) {
        switcherMini.addEventListener("click", () => {
          switcherBar.classList.remove("minimized");
          if (switcherToggle) switcherToggle.textContent = "−";
        });
      }

      // Keyboard shortcuts: Alt + 1 (Option A), Alt + 2 (Option B), Alt + 3 (Option C), Alt + 0 (Original)
      window.addEventListener("keydown", (e) => {
        if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") return;
        if (e.altKey) {
          const keyMap = {
            "1": "option-a",
            "2": "option-b",
            "3": "option-c",
            "0": "original",
            "Digit1": "option-a",
            "Digit2": "option-b",
            "Digit3": "option-c",
            "Digit0": "original",
            "¡": "option-a",
            "™": "option-b",
            "£": "option-c",
            "º": "original"
          };
          const target = keyMap[e.key] || keyMap[e.code];
          if (target) {
            e.preventDefault();
            switchVariant(target, true);
          }
        }
      });
    }
  });

  // Export globally
  window.xomskyVariants = {
    switchVariant,
    updateCategoryState,
    updateHybridStage: updateCategoryState,
    playTactileClick,
    showCopyToast,
    handleMascotReaction
  };
})();
