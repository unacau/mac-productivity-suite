/**
 * Khomyak (Хомяк) — Ethereal Bright Liminal 3D Giant Hamster Experience
 * Ultra-clean, photorealistic giant geometric Bauhaus hamster filling the screen.
 */

// ==========================================================================
// 1. Audio Engine
// ==========================================================================
class ASMRSoundEngine {
  constructor() {
    this.ctx = null;
    this.soundOn = true;
  }
  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();
    }
    if (this.ctx && this.ctx.state === "suspended") this.ctx.resume();
  }
  toggle() {
    this.soundOn = !this.soundOn;
    return this.soundOn;
  }
  playClick() {
    if (!this.soundOn) return;
    try {
      this.init();
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(750, now);
      osc.frequency.exponentialRampToValueAtTime(120, now + 0.035);
      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
      osc.connect(gain); gain.connect(this.ctx.destination);
      osc.start(now); osc.stop(now + 0.045);
    } catch(e) {}
  }
  playChime() {
    if (!this.soundOn) return;
    try {
      this.init();
      const now = this.ctx.currentTime;
      [587.33, 739.99, 880.00, 1108.73].forEach((f, i) => {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        const st = now + i * 0.045;
        osc.type = "triangle";
        osc.frequency.setValueAtTime(f, st);
        gain.gain.setValueAtTime(0.14, st);
        gain.gain.exponentialRampToValueAtTime(0.001, st + 0.35);
        osc.connect(gain); gain.connect(this.ctx.destination);
        osc.start(st); osc.stop(st + 0.4);
      });
    } catch(e) {}
  }
  playRelayClick(toDark = true) {
    if (!this.soundOn) return;
    try {
      this.init();
      const now = this.ctx.currentTime;
      if (toDark) {
        // Deep mechanical relay click: transient impulse + resonant sub-bass thump (lights out)
        const osc1 = this.ctx.createOscillator();
        const gain1 = this.ctx.createGain();
        osc1.type = "sine";
        osc1.frequency.setValueAtTime(420, now);
        osc1.frequency.exponentialRampToValueAtTime(55, now + 0.08);
        gain1.gain.setValueAtTime(0.35, now);
        gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
        osc1.connect(gain1); gain1.connect(this.ctx.destination);
        osc1.start(now); osc1.stop(now + 0.13);

        const osc2 = this.ctx.createOscillator();
        const gain2 = this.ctx.createGain();
        osc2.type = "triangle";
        osc2.frequency.setValueAtTime(120, now + 0.015);
        osc2.frequency.exponentialRampToValueAtTime(40, now + 0.15);
        gain2.gain.setValueAtTime(0.25, now + 0.015);
        gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.20);
        osc2.connect(gain2); gain2.connect(this.ctx.destination);
        osc2.start(now + 0.015); osc2.stop(now + 0.22);
      } else {
        // Crisp high-frequency switch flick + upward crystalline tone (lights on)
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = "sine";
        osc.frequency.setValueAtTime(440, now);
        osc.frequency.exponentialRampToValueAtTime(880, now + 0.06);
        gain.gain.setValueAtTime(0.20, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);
        osc.connect(gain); gain.connect(this.ctx.destination);
        osc.start(now); osc.stop(now + 0.10);
      }
    } catch(e) {}
  }
}

const sound = new ASMRSoundEngine();

// ==========================================================================
// 2. Profile Data
// ==========================================================================
// 2. Profile Data (Matching Native macOS Google Chrome Profiles)
// ==========================================================================
const PROFILES = [
  {
    name: "Igor",
    headerName: "Igor",
    email: "igorekishev92@gmail.com",
    avatarImg: "assets/images/profiles/igor.png",
    avatarBg: "linear-gradient(135deg, #6366F1 0%, #A855F7 100%)",
    avatarEmoji: "👤",
    initial: "I",
    className: "avatar-igor",
    windows: 11,
    tabs: ["Linear Team Core", "Claude 3.7", "Antigravity"],
    url: "https://linear.app/team-core",
    color: "#8B5CF6"
  },
  {
    name: "Al11",
    headerName: "Al11 (Igor)",
    email: "igor@almosteleven.com",
    avatarImg: "assets/images/profiles/ai11.png",
    avatarBg: "linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)",
    avatarEmoji: "🔥",
    initial: "A",
    className: "avatar-ai11",
    windows: 6,
    tabs: ["GitHub Pull Requests", "CI Pipeline", "Terminal"],
    url: "https://github.com/unacau/mac-productivity-suite",
    color: "#3B82F6"
  },
  {
    name: "GCP Free Trial",
    headerName: "GCP Free Trial",
    email: "igorekishev729@gmail.com",
    avatarImg: "assets/images/profiles/gcp.png",
    avatarBg: "linear-gradient(135deg, #EC4899 0%, #F43F5E 100%)",
    avatarEmoji: "🕶️",
    initial: "G",
    className: "avatar-gcp",
    windows: 4,
    tabs: ["Google Cloud Console", "Vertex AI", "Billing"],
    url: "https://console.cloud.google.com",
    color: "#EC4899"
  },
  {
    name: "Nastya",
    headerName: "Nastya",
    email: "betapoozytron@gmail.com",
    avatarImg: "assets/images/profiles/nastya.png",
    avatarBg: "linear-gradient(135deg, #1E293B 0%, #0F172A 100%)",
    avatarEmoji: "🖤",
    initial: "N",
    className: "avatar-nastya",
    windows: 2,
    tabs: ["Figma Design Specs", "Notion Shared", "Spotify"],
    url: "https://figma.com",
    color: "#10B981"
  }
];

// Camera View Presets (Dynamic 3/4 Hero View vs Cute Butt View vs Front View)
const CAM_PRESETS = {
  hero: {
    pos: new THREE.Vector3(1.65, 1.15, 4.80),
    target: new THREE.Vector3(-0.35, 0.08, 0.15)
  },
  rear: {
    pos: new THREE.Vector3(0.35, 1.15, -4.90),
    target: new THREE.Vector3(-0.35, 0.08, 0.10)
  },
  front: {
    pos: new THREE.Vector3(1.00, 1.15, 5.20),
    target: new THREE.Vector3(-0.35, 0.08, 0.10)
  }
};

let currentCamView = "hero"; // Default to dynamic 3/4 Hero view (balanced & shows profile + glowing keycap)
let targetCamPos = CAM_PRESETS.hero.pos.clone();
let targetCamLook = CAM_PRESETS.hero.target.clone();
let isCamTransitioning = false;

function setCameraView(viewName, smooth = true) {
  currentCamView = viewName;
  const preset = CAM_PRESETS[viewName] || CAM_PRESETS.hero;
  targetCamPos.copy(preset.pos);
  targetCamLook.copy(preset.target);

  if (!smooth && camera && controls) {
    camera.position.copy(preset.pos);
    controls.target.copy(preset.target);
    controls.update();
  } else {
    isCamTransitioning = true;
  }
  updateCamBtnLabel();
}

function toggleCameraView() {
  const next = currentCamView === "rear" ? "hero" : "rear";
  setCameraView(next, true);
  sound.playClick();
}

function updateCamBtnLabel() {
  const icon = document.getElementById("cam-view-icon");
  const text = document.getElementById("cam-view-text");
  const btn = document.getElementById("cam-view-btn");
  if (!btn) return;
  if (currentCamView === "rear") {
    if (icon) icon.textContent = "🐹";
    if (text) text.textContent = "Face View";
    btn.title = "Switch to front view (V)";
  } else {
    if (icon) icon.textContent = "🍑";
    if (text) text.textContent = "Butt View";
    btn.title = "Switch to cute rear butt view (V)";
  }
}

const CATEGORY_DATA = {
  chrome: {
    title: "Google Chrome",
    shortcut: "Caps-Lock + C",
    color: "#3B82F6"
  },
  terminal: {
    title: "Terminal (iTerm2)",
    shortcut: "Caps-Lock + T",
    color: "#10B981",
    lines: [
      "$ swift test",
      "Building for debugging...",
      "✔ Test suite 'ChromeQuickAccessTests' passed (0.042s)",
      "12 tests passed, 0 failures.",
      "igorekishev@MacBook-Pro git:(main) ▋"
    ]
  },
  ide: {
    title: "IDE (Antigravity IDE)",
    shortcut: "Caps-Lock + I",
    color: "#6366F1",
    lines: [
      "// AppGroupEngine.swift — 5-Category Suite",
      "public static let ide = AppGroupEngine(",
      "  category: \"IDE\",",
      "  candidates: [AppCandidate(\"Antigravity IDE\")]",
      ") // sub-16ms CGEventTap window focus"
    ]
  },
  ai: {
    title: "AI Agent (Antigravity)",
    shortcut: "Caps-Lock + A",
    color: "#06B6D4",
    message: "Verified 100% native CGEventTap architecture without background daemons. Context switches execute in 1 display frame."
  },
  notes: {
    title: "Notes (Apple Notes)",
    shortcut: "Caps-Lock + N",
    color: "#F59E0B",
    tasks: [
      "☑ Zero-latency Caps-Lock Hyper Key",
      "☑ 5-App Toolkit Fast Switcher",
      "☑ Universal Copy-on-Select",
      "☐ Ship Xomsky v1.0.0 Release"
    ]
  }
};

let activeIndex = 0;
let currentCategory = "chrome";
let userInteracted = false;

// ==========================================================================
// 3. Three.js Scene: Luminous Liminal Space & Midnight Obsidian Studio
// ==========================================================================
let scene, camera, renderer, controls;
let hamsterRoot, cheeksGroup, eyesGroup, snoutGroup;
let eyeLeft, eyeRight;
let leftEarGroup, rightEarGroup;
let whiskersGroup, tailMesh;
let keyboardGroup;
let interactiveKeyMeshes = [];
let keyMeshMap = {};

let mouseX = 0, mouseY = 0;
let targetHeadX = 0, targetHeadY = 0;
let raycaster, mouseVec;
let mouseMoved = true;

// Dynamic Environment & Lighting References
let floorMesh, floorMat;
let panelMesh, panelMat;
let ambientLight, keyLight, rimLightL, rimLightR, fillLight;
let pillarMat, pillarMeshes = [];
let chassisMesh, chassisMat, plateMesh, plateMat, glowStripMesh, glowStripMat;

// Theme Engine: System Theme Auto-Detection (dark/light) with user manual toggle
function getSystemTheme() {
  return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function getPreferredTheme() {
  try {
    const override = localStorage.getItem("xomsky_theme_override");
    if (override === "dark" || override === "light") {
      return override;
    }
  } catch (e) {}
  return getSystemTheme();
}

let currentTheme = getPreferredTheme();

const THEMES = {
  light: {
    bg: 0xFDF8FA,
    fogDensity: 0.022,
    ambientColor: 0xFFF0F5,
    ambientIntensity: 1.05,
    keyLightColor: 0xFFFFFF,
    keyLightIntensity: 1.35,
    rimLColor: 0xF472B6,
    rimLIntensity: 1.25,
    rimRColor: 0xF5A623,
    rimRIntensity: 0.0,
    fillColor: 0xFCE7F3,
    fillIntensity: 0.80,
    floorColor: 0xFFFFFF,
    floorRoughness: 0.15,
    floorMetalness: 0.15,
    panelColor: 0xFFFFFF,
    pillarColor: 0xFDF2F8,
    pillarRoughness: 0.60,
    pillarMetalness: 0.0,
    chassisColor: 0x1E222D,
    chassisRoughness: 0.32,
    chassisMetalness: 0.82,
    plateColor: 0x141820,
    plateRoughness: 0.45,
    plateMetalness: 0.65,
    glowStripColor: 0x38BDF8
  },
  dark: {
    bg: 0x0B1120, // Brandbook Midnight Navy
    fogDensity: 0.030,
    ambientColor: 0x1E293B,
    ambientIntensity: 0.70,
    keyLightColor: 0x94A3B8,
    keyLightIntensity: 0.55,
    rimLColor: 0x38BDF8, // Electric Cyan rim sculpting cheeks and keyboard
    rimLIntensity: 2.80,
    rimRColor: 0xF5A623, // Warm Hamster Gold rim contouring from right
    rimRIntensity: 2.20,
    fillColor: 0x0F172A,
    fillIntensity: 0.35,
    floorColor: 0x070B14, // Smoked Obsidian Mirror Floor
    floorRoughness: 0.08,
    floorMetalness: 0.85,
    panelColor: 0x0F172A, // Softbox shut down
    pillarColor: 0x0B1222,
    pillarRoughness: 0.70,
    pillarMetalness: 0.30,
    chassisColor: 0x0A0F1D,
    chassisRoughness: 0.28,
    chassisMetalness: 0.90,
    plateColor: 0x060911,
    plateRoughness: 0.35,
    plateMetalness: 0.80,
    glowStripColor: 0x38BDF8
  }
};

let themeTransition = {
  active: false,
  progress: 1.0,
  duration: 0.45,
  from: {},
  to: {}
};

function initThreeJS() {
  const container = document.getElementById("canvas-container");
  const width = window.innerWidth;
  const height = window.innerHeight;

  const initTheme = THEMES[currentTheme] || THEMES.dark;

  // Scene & Atmosphere
  scene = new THREE.Scene();
  scene.background = new THREE.Color(initTheme.bg);
  scene.fog = new THREE.FogExp2(initTheme.bg, initTheme.fogDensity);

  // Camera: Placed by default in dynamic 3/4 hero view
  camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 1000);
  camera.position.copy(CAM_PRESETS.hero.pos);

  // Renderer
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: "high-performance" });
  renderer.setSize(width, height);
  // Restore high quality on Retina displays
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.05;
  window.__renderer = renderer;
  container.appendChild(renderer.domElement);

  // OrbitControls
  controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.06;
  controls.maxPolarAngle = Math.PI / 2 - 0.02;
  controls.minDistance = 2.4;
  controls.maxDistance = 8.0;
  controls.target.copy(CAM_PRESETS.hero.target);
  controls.addEventListener("start", () => { isCamTransitioning = false; });

  // Raycasting
  raycaster = new THREE.Raycaster();
  mouseVec = new THREE.Vector2();

  // Build Scene
  buildBrightLiminalEnvironment();
  buildGiantRealisticHamster();
  buildMechanicalKeyboardDeck();

  // Events
  window.addEventListener("resize", onWindowResize);
  window.addEventListener("mousemove", onMouseMove);
  container.addEventListener("pointerdown", onPointerDown);

  animate();
}

// --------------------------------------------------------------------------
// Luminous Liminal Environment
// --------------------------------------------------------------------------
function buildBrightLiminalEnvironment() {
  const t = THEMES[currentTheme] || THEMES.dark;
  // Force Space Gray / Dark colors for the keyboard
  const chassisColorOverride = 0x2A2A2E;
  const plateColorOverride = 0x1C1C1F;

  // Luminous Marble / Smoked Obsidian Floor
  const floorGeo = new THREE.PlaneGeometry(250, 250);
  floorMat = new THREE.MeshStandardMaterial({
    color: t.floorColor,
    roughness: t.floorRoughness,
    metalness: t.floorMetalness
  });
  floorMesh = new THREE.Mesh(floorGeo, floorMat);
  floorMesh.position.y = -0.6;
  floorMesh.rotation.x = -Math.PI / 2;
  floorMesh.receiveShadow = true;
  scene.add(floorMesh);

  // Overhead Luminous Softbox Panel
  const panelGeo = new THREE.BoxGeometry(12, 0.1, 5);
  panelMat = new THREE.MeshBasicMaterial({ color: t.panelColor });
  panelMesh = new THREE.Mesh(panelGeo, panelMat);
  panelMesh.position.set(0, 7.5, 0);
  scene.add(panelMesh);

  // Ambient Light: Bright Radiant or Deep Midnight Indigo
  ambientLight = new THREE.AmbientLight(t.ambientColor, t.ambientIntensity);
  scene.add(ambientLight);

  // Studio Key Light
  keyLight = new THREE.DirectionalLight(t.keyLightColor, t.keyLightIntensity);
  keyLight.position.set(4, 8, 6);
  keyLight.castShadow = true;
  keyLight.shadow.mapSize.width = 2048;
  keyLight.shadow.mapSize.height = 2048;
  keyLight.shadow.bias = -0.0004;
  scene.add(keyLight);

  // Dual Sculpting Rim Lights
  // Left Rim Light (Pink in light, Electric Cyan in dark)
  rimLightL = new THREE.DirectionalLight(t.rimLColor, t.rimLIntensity);
  rimLightL.position.set(-5, 4.5, -5);
  scene.add(rimLightL);

  // Right Rim Light (Warm Hamster Gold in dark)
  rimLightR = new THREE.DirectionalLight(t.rimRColor, t.rimRIntensity);
  rimLightR.position.set(5, 4.0, -4);
  scene.add(rimLightR);

  // Front Soft Fill
  fillLight = new THREE.PointLight(t.fillColor, t.fillIntensity, 12);
  fillLight.position.set(0, 1.2, 3.5);
  scene.add(fillLight);

  // Rear Soft Fill (Illuminating the cute butt view)
  const rearFill = new THREE.PointLight(t.fillColor, t.fillIntensity * 0.95, 14);
  rearFill.position.set(1.2, 2.5, -5.2);
  scene.add(rearFill);
}

// --------------------------------------------------------------------------
// Giant Geometric Bauhaus Hamster with Green LED Keycap (Liminal Experience)
// --------------------------------------------------------------------------
function buildGiantRealisticHamster() {
  hamsterRoot = new THREE.Group();
  hamsterRoot.position.set(-0.35, -0.45, 0);
  hamsterRoot.scale.set(0.68, 0.68, 0.68);

  // Bauhaus Palette Materials
  const bauhausYellowMat = new THREE.MeshStandardMaterial({
    color: 0xF59E0B, // Rich warm amber / golden-yellow
    roughness: 0.38,
    metalness: 0.04
  });

  const bauhausCreamMat = new THREE.MeshStandardMaterial({
    color: 0xFEF3C7, // Warm Bauhaus ivory / cream
    roughness: 0.40,
    metalness: 0.02
  });

  const bauhausRedMat = new THREE.MeshStandardMaterial({
    color: 0xEF4444, // Vibrant Bauhaus signal red
    emissive: 0x991B1B,
    emissiveIntensity: 0.30,
    roughness: 0.25,
    metalness: 0.05
  });

  const bauhausOutlineMat = new THREE.MeshBasicMaterial({
    color: 0x111827 // Deep ink black graphic outline
  });

  const eyeObsidianMat = new THREE.MeshStandardMaterial({
    color: 0x0A0A0C, // Glossy deep obsidian black
    roughness: 0.05,
    metalness: 0.30
  });

  const whitePawMat = new THREE.MeshStandardMaterial({
    color: 0xFFFFFF,
    roughness: 0.35,
    metalness: 0.02
  });

  const pinkPadMat = new THREE.MeshStandardMaterial({
    color: 0xF43F5E, // Vibrant cute rose pink
    roughness: 0.30,
    metalness: 0.05
  });

  // 1. Cheeks & Head Group (Kinetic Squish Pivot)
  cheeksGroup = new THREE.Group();
  cheeksGroup.position.set(0, 0.92, 0.1);

  // Upper Head Spheres (Two overlapping yellow volumes)
  const headGeo = new THREE.SphereGeometry(0.72, 36, 36);
  headGeo.scale(1.15, 0.98, 0.65);

  const headL = new THREE.Mesh(headGeo, bauhausYellowMat);
  headL.position.set(-0.48, 0.22, 0);
  headL.castShadow = true;
  cheeksGroup.add(headL);

  const headR = new THREE.Mesh(headGeo, bauhausYellowMat);
  headR.position.set(0.48, 0.22, 0);
  headR.castShadow = true;
  cheeksGroup.add(headR);

  // Central Vertical Cream Forehead & Muzzle Bridge
  const centerWedgeGeo = new THREE.SphereGeometry(0.68, 36, 36);
  centerWedgeGeo.scale(0.82, 1.12, 0.72);
  const centerWedge = new THREE.Mesh(centerWedgeGeo, bauhausCreamMat);
  centerWedge.position.set(0, 0.18, 0.12);
  centerWedge.castShadow = true;
  cheeksGroup.add(centerWedge);

  // Lower Giant Puffed Cheeks (Overlapping yellow & cream circles)
  const lowerCheekGeo = new THREE.SphereGeometry(0.56, 32, 32);
  lowerCheekGeo.scale(1.18, 0.92, 0.68);

  const lowerCheekL = new THREE.Mesh(lowerCheekGeo, bauhausYellowMat);
  lowerCheekL.position.set(-0.66, -0.15, 0.2);
  lowerCheekL.castShadow = true;
  cheeksGroup.add(lowerCheekL);

  const lowerCheekR = new THREE.Mesh(lowerCheekGeo, bauhausYellowMat);
  lowerCheekR.position.set(0.66, -0.15, 0.2);
  lowerCheekR.castShadow = true;
  cheeksGroup.add(lowerCheekR);

  // Inner Cream Cheeks Patches
  const innerPatchGeo = new THREE.SphereGeometry(0.46, 32, 32);
  innerPatchGeo.scale(0.98, 0.95, 0.75);

  const innerL = new THREE.Mesh(innerPatchGeo, bauhausCreamMat);
  innerL.position.set(-0.28, -0.16, 0.32);
  cheeksGroup.add(innerL);

  const innerR = new THREE.Mesh(innerPatchGeo, bauhausCreamMat);
  innerR.position.set(0.28, -0.16, 0.32);
  cheeksGroup.add(innerR);

  // Center Chin Pad
  const chinGeo = new THREE.SphereGeometry(0.36, 24, 24);
  chinGeo.scale(1.12, 0.85, 0.75);
  const chin = new THREE.Mesh(chinGeo, bauhausCreamMat);
  chin.position.set(0, -0.32, 0.32);
  cheeksGroup.add(chin);

  hamsterRoot.add(cheeksGroup);

  // 2. Symmetrical Bauhaus Geometric Circular Ears
  const earOuterGeo = new THREE.CylinderGeometry(0.38, 0.38, 0.08, 36);
  earOuterGeo.rotateX(Math.PI / 2);
  const earInnerGeo = new THREE.CylinderGeometry(0.25, 0.25, 0.09, 36);
  earInnerGeo.rotateX(Math.PI / 2);
  const earRingGeo = new THREE.TorusGeometry(0.38, 0.018, 16, 48);
  const earInnerRingGeo = new THREE.TorusGeometry(0.25, 0.015, 16, 48);

  leftEarGroup = new THREE.Group();
  leftEarGroup.position.set(-0.70, 1.86, -0.05);
  leftEarGroup.rotation.z = 0.25;
  const lOuter = new THREE.Mesh(earOuterGeo, bauhausYellowMat);
  const lInner = new THREE.Mesh(earInnerGeo, bauhausCreamMat);
  lInner.position.z = 0.008;
  const lRing = new THREE.Mesh(earRingGeo, bauhausOutlineMat);
  lRing.position.z = 0.042;
  const lInnerRing = new THREE.Mesh(earInnerRingGeo, bauhausOutlineMat);
  lInnerRing.position.z = 0.046;
  leftEarGroup.add(lOuter, lInner, lRing, lInnerRing);
  hamsterRoot.add(leftEarGroup);

  rightEarGroup = new THREE.Group();
  rightEarGroup.position.set(0.70, 1.86, -0.05);
  rightEarGroup.rotation.z = -0.25;
  const rOuter = new THREE.Mesh(earOuterGeo, bauhausYellowMat);
  const rInner = new THREE.Mesh(earInnerGeo, bauhausCreamMat);
  rInner.position.z = 0.008;
  const rRing = new THREE.Mesh(earRingGeo, bauhausOutlineMat);
  rRing.position.z = 0.042;
  const rInnerRing = new THREE.Mesh(earInnerRingGeo, bauhausOutlineMat);
  rInnerRing.position.z = 0.046;
  rightEarGroup.add(rOuter, rInner, rRing, rInnerRing);
  hamsterRoot.add(rightEarGroup);

  // 3. Concentric Bauhaus Eyes (Outer Rings + Obsidian Core + Dual Glints)
  eyesGroup = new THREE.Group();
  eyesGroup.position.set(0, 1.28, 0.72);

  const eyeBaseGeo = new THREE.CylinderGeometry(0.35, 0.35, 0.04, 48);
  eyeBaseGeo.rotateX(Math.PI / 2);
  const eyeRingOuterGeo = new THREE.TorusGeometry(0.35, 0.018, 16, 64);
  const eyeRingInnerGeo = new THREE.TorusGeometry(0.27, 0.016, 16, 64);
  const eyeSphereGeo = new THREE.SphereGeometry(0.20, 32, 32);
  const glintBigGeo = new THREE.SphereGeometry(0.065, 16, 16);
  const glintSmallGeo = new THREE.SphereGeometry(0.032, 16, 16);
  const glintMat = new THREE.MeshBasicMaterial({ color: 0xFFFFFF });

  // Left Eye Sub-Assembly
  const eyeLGroup = new THREE.Group();
  eyeLGroup.position.set(-0.38, 0, 0.04);
  eyeLGroup.rotation.y = -0.08;

  const eyeBaseL = new THREE.Mesh(eyeBaseGeo, bauhausCreamMat);
  eyeLGroup.add(eyeBaseL);

  const ringOutL = new THREE.Mesh(eyeRingOuterGeo, bauhausOutlineMat);
  ringOutL.position.z = 0.025;
  eyeLGroup.add(ringOutL);

  const ringInL = new THREE.Mesh(eyeRingInnerGeo, bauhausOutlineMat);
  ringInL.position.z = 0.026;
  eyeLGroup.add(ringInL);

  eyeLeft = new THREE.Mesh(eyeSphereGeo, eyeObsidianMat);
  eyeLeft.position.z = 0.06;
  eyeLGroup.add(eyeLeft);

  const glintLBig = new THREE.Mesh(glintBigGeo, glintMat);
  glintLBig.position.set(-0.06, 0.06, 0.22);
  eyeLGroup.add(glintLBig);

  const glintLSmall = new THREE.Mesh(glintSmallGeo, glintMat);
  glintLSmall.position.set(0.07, -0.06, 0.22);
  eyeLGroup.add(glintLSmall);

  eyesGroup.add(eyeLGroup);

  // Right Eye Sub-Assembly
  const eyeRGroup = new THREE.Group();
  eyeRGroup.position.set(0.38, 0, 0.04);
  eyeRGroup.rotation.y = 0.08;

  const eyeBaseR = new THREE.Mesh(eyeBaseGeo, bauhausCreamMat);
  eyeRGroup.add(eyeBaseR);

  const ringOutR = new THREE.Mesh(eyeRingOuterGeo, bauhausOutlineMat);
  ringOutR.position.z = 0.025;
  eyeRGroup.add(ringOutR);

  const ringInR = new THREE.Mesh(eyeRingInnerGeo, bauhausOutlineMat);
  ringInR.position.z = 0.026;
  eyeRGroup.add(ringInR);

  eyeRight = new THREE.Mesh(eyeSphereGeo, eyeObsidianMat);
  eyeRight.position.z = 0.06;
  eyeRGroup.add(eyeRight);

  const glintRBig = new THREE.Mesh(glintBigGeo, glintMat);
  glintRBig.position.set(-0.06, 0.06, 0.22);
  eyeRGroup.add(glintRBig);

  const glintRSmall = new THREE.Mesh(glintSmallGeo, glintMat);
  glintRSmall.position.set(0.07, -0.06, 0.22);
  eyeRGroup.add(glintRSmall);

  eyesGroup.add(eyeRGroup);

  hamsterRoot.add(eyesGroup);

  // 4. Red Inverted Triangle Nose & Bauhaus Curved Smiling Mouth
  snoutGroup = new THREE.Group();
  snoutGroup.position.set(0, 0.98, 0.78);

  // Inverted Flat Triangular Prism (horizontal top, downward pointing vertex)
  const noseShape = new THREE.Shape();
  const nw = 0.20;
  const nh = 0.22;
  noseShape.moveTo(-nw, nh * 0.45);
  noseShape.lineTo(nw, nh * 0.45);
  noseShape.lineTo(0, -nh * 0.65);
  noseShape.closePath();

  const noseGeo = new THREE.ExtrudeGeometry(noseShape, { depth: 0.06, bevelEnabled: false });
  const noseMat = new THREE.MeshBasicMaterial({ color: 0xFF2A2A });
  const noseMesh = new THREE.Mesh(noseGeo, noseMat);
  noseMesh.position.z = -0.03;
  snoutGroup.add(noseMesh);

  // Clean dark outline around the red triangle
  const noseEdges = new THREE.EdgesGeometry(noseGeo);
  const noseLine = new THREE.LineSegments(noseEdges, new THREE.LineBasicMaterial({ color: 0x111827, linewidth: 2 }));
  noseLine.position.z = -0.03;
  snoutGroup.add(noseLine);

  // Curved Black Smile Lines (Bauhaus W-mouth)
  const curveL = new THREE.QuadraticBezierCurve3(
    new THREE.Vector3(-0.32, -0.15, -0.05),
    new THREE.Vector3(-0.16, -0.28, 0.02),
    new THREE.Vector3(0, -0.14, 0.04)
  );
  const smileL = new THREE.Mesh(new THREE.TubeGeometry(curveL, 20, 0.022, 8, false), bauhausOutlineMat);
  snoutGroup.add(smileL);

  const curveR = new THREE.QuadraticBezierCurve3(
    new THREE.Vector3(0, -0.14, 0.04),
    new THREE.Vector3(0.16, -0.28, 0.02),
    new THREE.Vector3(0.32, -0.15, -0.05)
  );
  const smileR = new THREE.Mesh(new THREE.TubeGeometry(curveR, 20, 0.022, 8, false), bauhausOutlineMat);
  snoutGroup.add(smileR);

  hamsterRoot.add(snoutGroup);

  // 5. Pure White Paws with Pink Pads Resting on Keycap
  const pawGeo = new THREE.SphereGeometry(0.19, 24, 24);
  pawGeo.scale(1.15, 0.95, 1.15);
  const padGeo = new THREE.SphereGeometry(0.042, 16, 16);

  // Left Paw
  const leftPawGroup = new THREE.Group();
  leftPawGroup.position.set(-0.36, 0.28, 0.86);
  leftPawGroup.rotation.x = 0.20;
  const leftPawMesh = new THREE.Mesh(pawGeo, whitePawMat);
  leftPawGroup.add(leftPawMesh);
  [
    [-0.08, -0.07, 0.15],
    [0.0, -0.09, 0.17],
    [0.08, -0.07, 0.15]
  ].forEach(p => {
    const pad = new THREE.Mesh(padGeo, pinkPadMat);
    pad.position.set(...p);
    leftPawGroup.add(pad);
  });
  hamsterRoot.add(leftPawGroup);

  // Right Paw
  const rightPawGroup = new THREE.Group();
  rightPawGroup.position.set(0.36, 0.28, 0.86);
  rightPawGroup.rotation.x = 0.20;
  const rightPawMesh = new THREE.Mesh(pawGeo, whitePawMat);
  rightPawGroup.add(rightPawMesh);
  [
    [-0.08, -0.07, 0.15],
    [0.0, -0.09, 0.17],
    [0.08, -0.07, 0.15]
  ].forEach(p => {
    const pad = new THREE.Mesh(padGeo, pinkPadMat);
    pad.position.set(...p);
    rightPawGroup.add(pad);
  });
  hamsterRoot.add(rightPawGroup);

  // 6. Soft Hind Feet Resting on Floor
  const footGeo = new THREE.SphereGeometry(0.24, 20, 20);
  footGeo.scale(1.2, 0.5, 1.5);
  const leftFoot = new THREE.Mesh(footGeo, bauhausYellowMat);
  leftFoot.position.set(-0.74, -0.08, 0.28);
  hamsterRoot.add(leftFoot);

  const rightFoot = new THREE.Mesh(footGeo, bauhausYellowMat);
  rightFoot.position.set(0.74, -0.08, 0.28);
  hamsterRoot.add(rightFoot);

  tailMesh = null;

  scene.add(hamsterRoot);
}

// --------------------------------------------------------------------------
// 3D Mechanical Keyboard Command Deck (60% Layout with Highlighted Keys)
// --------------------------------------------------------------------------
const keycapTextureCache = {};

function createKeycapTexture(label, isInteractive, accentColor, hasLed, isCaps) {
  const cacheKey = `${label}_${isInteractive}_${accentColor || ""}_${hasLed || ""}_${isCaps || ""}`;
  if (keycapTextureCache[cacheKey]) return keycapTextureCache[cacheKey];

  const canvas = document.createElement("canvas");
  canvas.width = 128;
  canvas.height = 128;
  const ctx = canvas.getContext("2d");

  // Keycap base gradient
  const bgGrad = ctx.createLinearGradient(0, 0, 0, 128);
  if (isCaps) {
    bgGrad.addColorStop(0, "#1E1B4B");
    bgGrad.addColorStop(1, "#0F172A");
  } else if (isInteractive) {
    bgGrad.addColorStop(0, "#1E293B");
    bgGrad.addColorStop(1, "#0F172A");
  } else {
    bgGrad.addColorStop(0, "#182030");
    bgGrad.addColorStop(1, "#0F1420");
  }
  ctx.fillStyle = bgGrad;
  ctx.beginPath();
  ctx.roundRect(4, 4, 120, 120, 14);
  ctx.fill();

  // Chamfered Inner Bevel Border
  ctx.strokeStyle = isInteractive ? (accentColor || "#38BDF8") : "rgba(255, 255, 255, 0.12)";
  ctx.lineWidth = isInteractive ? 4 : 2;
  ctx.stroke();

  // Top Inset Highlight
  ctx.strokeStyle = "rgba(255, 255, 255, 0.18)";
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.roundRect(8, 8, 112, 112, 10);
  ctx.stroke();

  // Glowing LED for Caps Lock
  if (hasLed) {
    ctx.fillStyle = "#22C55E";
    ctx.beginPath();
    ctx.arc(24, 24, 5, 0, Math.PI * 2);
    ctx.fill();
  }

  // Golden Upward Arrow for Caps Lock
  if (isCaps) {
    ctx.save();
    ctx.translate(64, 50);
    ctx.beginPath();
    ctx.moveTo(0, -21);
    ctx.lineTo(18, -4);
    ctx.lineTo(8, -4);
    ctx.lineTo(8, 16);
    ctx.lineTo(-8, 16);
    ctx.lineTo(-8, -4);
    ctx.lineTo(-18, -4);
    ctx.closePath();
    ctx.fillStyle = "#F59E0B";
    ctx.fill();
    ctx.strokeStyle = "#0F172A";
    ctx.lineWidth = 2.5;
    ctx.stroke();
    ctx.restore();

    ctx.fillStyle = "#FFFFFF";
    ctx.font = "bold 14px -apple-system, BlinkMacSystemFont, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("caps", 64, 92);
  } else {
    // Standard or Highlighted Legend
    ctx.fillStyle = isInteractive ? (accentColor || "#FFFFFF") : "#94A3B8";
    ctx.font = isInteractive ? "bold 38px -apple-system, BlinkMacSystemFont, monospace" : "bold 30px -apple-system, BlinkMacSystemFont, monospace";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(label, 64, 64);
  }

  const texture = new THREE.CanvasTexture(canvas);
  texture.anisotropy = 4;
  keycapTextureCache[cacheKey] = texture;
  return texture;
}

function buildMechanicalKeyboardDeck() {
  keyboardGroup = new THREE.Group();
  keyboardGroup.scale.set(0.48, 0.48, 0.48); // Scaled proportionally with hamster
  keyboardGroup.position.set(-0.35, -0.42, 0.95); // Aligned cleanly with hamster
  keyboardGroup.rotation.y = 0; // Spacebar facing user
  keyboardGroup.rotation.x = 0.12; // Ergonomic 7° Apple tilt

  const t = THEMES[currentTheme] || THEMES.dark;
  const chassisColorOverride = 0x1E222D; // Space Gray / Dark Obsidian
  const plateColorOverride = 0x141820;

  // 1. Keyboard Chassis (Dark Anodized Aluminum / Slate)
  const chassisGeo = new THREE.BoxGeometry(2.78, 0.11, 1.10);
  chassisMat = new THREE.MeshStandardMaterial({
    color: chassisColorOverride,
    roughness: t.chassisRoughness,
    metalness: t.chassisMetalness
  });
  chassisMesh = new THREE.Mesh(chassisGeo, chassisMat);
  chassisMesh.position.y = -0.055;
  chassisMesh.castShadow = true;
  chassisMesh.receiveShadow = true;
  keyboardGroup.add(chassisMesh);

  // Top Plate Inset
  const plateGeo = new THREE.BoxGeometry(2.70, 0.03, 1.02);
  plateMat = new THREE.MeshStandardMaterial({
    color: plateColorOverride,
    roughness: t.plateRoughness,
    metalness: t.plateMetalness
  });
  plateMesh = new THREE.Mesh(plateGeo, plateMat);
  plateMesh.position.y = 0.005;
  keyboardGroup.add(plateMesh);

  // Neon Underglow Strips (Front edge facing viewer and rear edge facing hamster)
  const glowStripGeo = new THREE.BoxGeometry(2.68, 0.015, 0.015);
  glowStripMat = new THREE.MeshBasicMaterial({ color: t.glowStripColor });
  glowStripMesh = new THREE.Mesh(glowStripGeo, glowStripMat);
  glowStripMesh.position.set(0, -0.01, -0.54); // Facing viewer along front deck edge
  keyboardGroup.add(glowStripMesh);

  const glowStripRear = new THREE.Mesh(glowStripGeo, glowStripMat);
  glowStripRear.position.set(0, -0.01, 0.54); // Facing hamster under spacebar
  keyboardGroup.add(glowStripRear);

  // 2. Key Matrix Layout
  const unitSize = 0.155;
  const keyGap = 0.022;
  const step = unitSize + keyGap; // ~0.177
  const startZ = -0.36;

  // Key creation helper
  function addKey(x, z, widthUnits, label, options = {}) {
    const keyWidth = unitSize * widthUnits + keyGap * (widthUnits - 1);
    const keyDepth = unitSize;
    const keyHeight = 0.075;

    const topTex = createKeycapTexture(
      label,
      options.isInteractive,
      options.accentColor,
      options.hasLed,
      options.isCaps
    );

    const sideMat = new THREE.MeshStandardMaterial({
      color: options.isCaps ? 0x1A2238 : (options.isInteractive ? 0x1E293B : 0x121824),
      roughness: 0.4,
      metalness: 0.3
    });

    const topMat = new THREE.MeshStandardMaterial({
      map: topTex,
      roughness: 0.28,
      metalness: 0.25,
      emissive: options.accentColor ? new THREE.Color(options.accentColor) : new THREE.Color(0x000000),
      emissiveIntensity: options.isInteractive ? 0.35 : 0.0
    });

    // Box materials: [+X, -X, +Y(top), -Y, +Z, -Z]
    const keyMesh = new THREE.Mesh(
      new THREE.BoxGeometry(keyWidth, keyHeight, keyDepth),
      [sideMat, sideMat, topMat, sideMat, sideMat, sideMat]
    );

    const baseY = 0.055;
    keyMesh.position.set(x, baseY, z);
    keyMesh.castShadow = true;
    keyMesh.receiveShadow = true;

    keyMesh.userData = {
      label: label,
      basePosY: baseY,
      isInteractive: !!options.isInteractive,
      category: options.category || null,
      subIndex: options.subIndex !== undefined ? options.subIndex : null,
      keyId: options.keyId || label.toLowerCase(),
      accentColor: options.accentColor || null
    };

    if (options.hasLed) {
      const ledLight = new THREE.PointLight(0x22C55E, 2.5, 1.6);
      ledLight.position.set(-keyWidth * 0.26, keyHeight * 0.6, -keyDepth * 0.2);
      keyMesh.add(ledLight);
      keyMesh.userData.ledLight = ledLight;
    }

    if (options.isInteractive) {
      interactiveKeyMeshes.push(keyMesh);
      keyMeshMap[keyMesh.userData.keyId] = keyMesh;
    }

    keyboardGroup.add(keyMesh);
    return keyMesh;
  }

  // Row 0: Numbers Row (Z = -0.36)
  let curX = -1.22;
  addKey(curX + 0.5 * step, startZ, 1.0, "Esc");
  curX += step;
  
  // Highlighted Profile slots 1..4
  addKey(curX + 0.5 * step, startZ, 1.0, "1", { isInteractive: true, category: "chrome", subIndex: 0, keyId: "1", accentColor: "#F43F5E" });
  curX += step;
  addKey(curX + 0.5 * step, startZ, 1.0, "2", { isInteractive: true, category: "chrome", subIndex: 1, keyId: "2", accentColor: "#10B981" });
  curX += step;
  addKey(curX + 0.5 * step, startZ, 1.0, "3", { isInteractive: true, category: "chrome", subIndex: 2, keyId: "3", accentColor: "#F59E0B" });
  curX += step;
  addKey(curX + 0.5 * step, startZ, 1.0, "4", { isInteractive: true, category: "chrome", subIndex: 3, keyId: "4", accentColor: "#06B6D4" });
  curX += step;

  ["5", "6", "7", "8", "9", "0", "-", "="].forEach(k => {
    addKey(curX + 0.5 * step, startZ, 1.0, k);
    curX += step;
  });
  addKey(curX + 0.75 * step, startZ, 1.5, "Bksp");

  // Row 1: QWERTY Row (Z = -0.18)
  curX = -1.22;
  addKey(curX + 0.7 * step, startZ + step, 1.4, "Tab");
  curX += 1.4 * step;

  ["Q", "W", "E", "R"].forEach(k => {
    addKey(curX + 0.5 * step, startZ + step, 1.0, k);
    curX += step;
  });

  // Highlighted T for Terminal
  addKey(curX + 0.5 * step, startZ + step, 1.0, "T", { isInteractive: true, category: "terminal", keyId: "t", accentColor: "#10B981" });
  curX += step;

  ["Y", "U"].forEach(k => {
    addKey(curX + 0.5 * step, startZ + step, 1.0, k);
    curX += step;
  });

  // Highlighted I for IDE
  addKey(curX + 0.5 * step, startZ + step, 1.0, "I", { isInteractive: true, category: "ide", keyId: "i", accentColor: "#6366F1" });
  curX += step;

  ["O", "P", "[", "]", "\\"].forEach(k => {
    addKey(curX + 0.5 * step, startZ + step, 1.0, k);
    curX += step;
  });

  // Row 2: Home Row (Z = 0.0)
  curX = -1.22;
  // Highlighted Caps Lock with green LED & golden arrow
  addKey(curX + 0.875 * step, startZ + step * 2, 1.75, "Caps", { isInteractive: true, isCaps: true, hasLed: true, category: "caps", keyId: "caps", accentColor: "#F59E0B" });
  curX += 1.75 * step;

  // Highlighted A for AI Agent
  addKey(curX + 0.5 * step, startZ + step * 2, 1.0, "A", { isInteractive: true, category: "ai", keyId: "a", accentColor: "#06B6D4" });
  curX += step;

  ["S", "D", "F", "G", "H", "J", "K", "L", ";", "'"].forEach(k => {
    addKey(curX + 0.5 * step, startZ + step * 2, 1.0, k);
    curX += step;
  });
  addKey(curX + 0.9 * step, startZ + step * 2, 1.8, "Enter");

  // Row 3: Shift Row (Z = 0.18)
  curX = -1.22;
  addKey(curX + 1.05 * step, startZ + step * 3, 2.1, "Shift");
  curX += 2.1 * step;

  ["Z", "X"].forEach(k => {
    addKey(curX + 0.5 * step, startZ + step * 3, 1.0, k);
    curX += step;
  });

  // Highlighted C for Chrome Profiles
  addKey(curX + 0.5 * step, startZ + step * 3, 1.0, "C", { isInteractive: true, category: "chrome", keyId: "c", accentColor: "#3B82F6" });
  curX += step;

  ["V", "B"].forEach(k => {
    addKey(curX + 0.5 * step, startZ + step * 3, 1.0, k);
    curX += step;
  });

  // Highlighted N for Notes
  addKey(curX + 0.5 * step, startZ + step * 3, 1.0, "N", { isInteractive: true, category: "notes", keyId: "n", accentColor: "#F59E0B" });
  curX += step;

  ["M", ",", ".", "/"].forEach(k => {
    addKey(curX + 0.5 * step, startZ + step * 3, 1.0, k);
    curX += step;
  });
  addKey(curX + 1.05 * step, startZ + step * 3, 2.1, "Shift");

  // Row 4: Spacebar Row (Z = 0.36)
  curX = -1.22;
  ["Ctrl", "Opt", "Cmd"].forEach(k => {
    addKey(curX + 0.625 * step, startZ + step * 4, 1.25, k);
    curX += 1.25 * step;
  });

  // Spacebar
  addKey(curX + 2.75 * step, startZ + step * 4, 5.5, "Xomsky Space");
  curX += 5.5 * step;

  ["Cmd", "Opt", "Fn", "Ctrl"].forEach(k => {
    addKey(curX + 0.625 * step, startZ + step * 4, 1.25, k);
    curX += 1.25 * step;
  });

  scene.add(keyboardGroup);
}

// --------------------------------------------------------------------------
// Live Simulated Native macOS HUD (Matching MinimalHUDWindow.swift)
// --------------------------------------------------------------------------
let hudPeekTimer = null;

function scheduleHUDPeek() {
  clearTimeout(hudPeekTimer);
  const hud = document.getElementById("native-mac-hud");
  if (hud) hud.classList.remove("peeking");

  hudPeekTimer = setTimeout(() => {
    if (hud && !hud.classList.contains("minimized")) {
      hud.classList.add("peeking");
    }
  }, 150); // Fast appearance
}

const ANTIGRAVITY_APPS = [
  { name: "Antigravity", icon: "assets/images/icon_antigravity.png", sub: "Agent Studio" },
  { name: "Antigravity IDE", icon: "assets/images/icon_antigravity_ide.png", sub: "Workspace IDE" }
];

function updateSimulatedHUD(category = "chrome", profileIdx = 0) {
  const appIcon = document.getElementById("hud-app-icon");
  const appTitle = document.getElementById("hud-app-title");
  const appSub = document.getElementById("hud-app-subtitle");
  const carousel = document.getElementById("hud-carousel");
  const previewTitle = document.getElementById("window-preview-title");
  const previewBody = document.getElementById("window-preview-body");

  if (!appIcon || !appTitle || !appSub || !carousel) return;

  // Reset peek easter egg on any state update
  scheduleHUDPeek();

  if (category === "chrome") {
    const profile = PROFILES[profileIdx] || PROFILES[0];
    appIcon.src = "assets/images/icon_chrome.png";
    appTitle.textContent = "Google Chrome";
    appSub.textContent = profile.name;
    appSub.style.display = "inline-block";
    carousel.style.display = "flex";

    // Build the 4 profile avatar items
    carousel.innerHTML = PROFILES.map((p, idx) => `
      <div class="hud-slot-item ${idx === profileIdx ? 'active' : ''}" data-index="${idx}" title="Profile ${idx + 1}: ${p.name}">
        <div class="hud-avatar-circle ${p.className}"><span>${p.initial}</span></div>
        <span class="hud-slot-num">${idx + 1}</span>
      </div>
    `).join("");

    carousel.querySelectorAll(".hud-slot-item").forEach((slot) => {
      slot.addEventListener("click", () => {
        const idx = parseInt(slot.getAttribute("data-index"), 10);
        activateCategory("chrome", idx, String(idx + 1), true);
      });
    });

    if (previewTitle) previewTitle.textContent = `Google Chrome — ${profile.name} Profile`;
    if (previewBody) {
      const tabsHtml = profile.tabs.map((tab, i) => `<span class="${i === 0 ? 'active-tab' : ''}">${tab}</span>`).join("");
      previewBody.innerHTML = `
        <div class="browser-omnibar">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
          <span class="omnibar-url">${profile.url}</span>
        </div>
        <div class="window-preview-tags">
          ${tabsHtml}
        </div>
      `;
    }
  } else if (category === "terminal") {
    appIcon.src = "assets/images/icon_iterm.png";
    appTitle.textContent = "iTerm";
    appSub.textContent = "Quick Slot [T]";
    appSub.style.display = "inline-block";
    carousel.style.display = "none";

    if (previewTitle) previewTitle.textContent = "iTerm — zsh (80x24)";
    if (previewBody) {
      previewBody.innerHTML = `
        <div class="terminal-preview-screen">
          <span class="term-prompt">➜ ~/mac-productivity-suite</span> <span class="term-cmd">swift test</span><br>
          <span style="color: #34D399;">✔ 70/70 tests passed (0.042s)</span><br>
          <span class="term-prompt">➜ ~/mac-productivity-suite</span> <span class="term-cursor"></span>
        </div>
      `;
    }
  } else if (category === "ide") {
    appIcon.src = "assets/images/icon_antigravity_ide.png";
    appTitle.textContent = "Antigravity IDE";
    appSub.textContent = "Quick Slot [I]";
    appSub.style.display = "inline-block";
    carousel.style.display = "none";

    if (previewTitle) previewTitle.textContent = "Antigravity IDE — AppDelegate.swift";
    if (previewBody) {
      previewBody.innerHTML = `
        <div class="terminal-preview-screen" style="color: #93C5FD; font-size: 9px; line-height: 1.5;">
          <span style="color: #F472B6;">import</span> SwiftUI<br>
          <span style="color: #F472B6;">import</span> AppKit<br>
          <span style="color: #60A5FA;">MinimalHUDWindow</span>.shared.<span style="color: #34D399;">showImmediate</span>()<br>
          <span style="color: #64748B;">// Raised window in 0ms with zero latency</span>
        </div>
      `;
    }
  } else if (category === "ai") {
    const itemIdx = (profileIdx >= 0 && profileIdx < ANTIGRAVITY_APPS.length) ? profileIdx : 0;
    const currentApp = ANTIGRAVITY_APPS[itemIdx];
    appIcon.src = currentApp.icon;
    appTitle.textContent = currentApp.name;
    appSub.textContent = currentApp.sub;
    appSub.style.display = "inline-block";
    carousel.style.display = "flex";

    carousel.innerHTML = ANTIGRAVITY_APPS.map((item, idx) => `
      <div class="hud-slot-item ${idx === itemIdx ? 'active' : ''}" data-index="${idx}" title="${item.name}">
        <div class="hud-avatar-circle" style="background: rgba(255,255,255,0.06); border: 0.75px solid rgba(255,255,255,0.18); overflow: hidden; padding: 3px;">
          <img src="${item.icon}" style="width: 100%; height: 100%; object-fit: contain; border-radius: 4px;">
        </div>
        <span class="hud-slot-num">${idx + 1}</span>
      </div>
    `).join("");

    carousel.querySelectorAll(".hud-slot-item").forEach((slot) => {
      slot.addEventListener("click", () => {
        const idx = parseInt(slot.getAttribute("data-index"), 10);
        activateCategory("ai", idx, "a", true);
      });
    });

    if (previewTitle) previewTitle.textContent = `${currentApp.name} — ${currentApp.sub}`;
    if (previewBody) {
      previewBody.innerHTML = `
        <div class="terminal-preview-screen" style="color: #C084FC; font-size: 9px; line-height: 1.5;">
          <span style="color: #38BDF8;">● Antigravity 2.0:</span> Pair programming active<br>
          <span style="color: #34D399;">✔ Hotkeys:</span> Caps+A (Agent) • Caps+1..4 (Profiles)<br>
          <span style="color: #94A3B8;">Tracing telemetry: 100% Langfuse instrumented</span>
        </div>
      `;
    }
  } else if (category === "notes") {
    appIcon.src = "assets/images/icon_notes.png";
    appTitle.textContent = "Apple Notes";
    appSub.textContent = "Quick Slot [N]";
    appSub.style.display = "inline-block";
    carousel.style.display = "none";

    if (previewTitle) previewTitle.textContent = "Apple Notes — Quick Scratchpad";
    if (previewBody) {
      previewBody.innerHTML = `
        <div class="terminal-preview-screen" style="color: #FCD34D; font-size: 9px; line-height: 1.5;">
          • 0ms Caps-Lock Hyper-Key context switching<br>
          • Native Swift 6 standalone binary (2.1 MB)<br>
          • Zero background daemons, 0% CPU
        </div>
      `;
    }
  } else if (category === "caps") {
    appIcon.src = "assets/images/AppIcon.png";
    appTitle.textContent = "Xomsky";
    appSub.textContent = "⇪ Hyper Modifier";
    appSub.style.display = "inline-block";
    carousel.style.display = "none";

    if (previewTitle) previewTitle.textContent = "Xomsky — Hyper-Key Status";
    if (previewBody) {
      previewBody.innerHTML = `
        <div class="terminal-preview-screen" style="color: #38BDF8; font-size: 9px; line-height: 1.5;">
          <span style="color: #34D399;">⚡ Caps-Lock Remapped:</span> Driverless F18 Hyper-Key<br>
          <span style="color: #E2E8F0;">Shortcuts:</span> C (Chrome) • T (Terminal) • I (IDE) • A (AI) • N (Notes)
        </div>
      `;
    }
  }
}

// --------------------------------------------------------------------------
// --------------------------------------------------------------------------
// Concept 1: 5-Key Cockpit Switchboard Widget Logic
// --------------------------------------------------------------------------
let activeCockpitSlot = "c";

const COCKPIT_SLOT_MAP = {
  c: "chrome",
  t: "terminal",
  i: "ide",
  a: "ai",
  n: "notes"
};

function selectCockpitSlot(slotKey = "c", triggerActivation = true) {
  activeCockpitSlot = slotKey;
  const category = COCKPIT_SLOT_MAP[slotKey] || "chrome";

  // Update button active styles
  document.querySelectorAll(".cockpit-key-btn").forEach(btn => {
    btn.classList.toggle("active", btn.getAttribute("data-slot") === slotKey);
  });

  // Switch visible slot panel
  document.querySelectorAll(".slot-panel").forEach(panel => {
    panel.classList.toggle("active", panel.id === `slot-panel-${slotKey}`);
  });

  // Update latency tag with realistic instant 0.01ms jitter
  const latencyTag = document.getElementById("cockpit-latency-tag");
  if (latencyTag) {
    const lat = (Math.random() * 0.02 + 0.01).toFixed(2);
    latencyTag.textContent = `${lat}ms · Swift 6`;
  }

  if (triggerActivation) {
    activateCategory(category, category === "chrome" ? activeIndex : 0, slotKey, true);
  }
}

function updateCockpitWidget(category, keyId) {
  let targetSlot = "c";
  for (const [k, cat] of Object.entries(COCKPIT_SLOT_MAP)) {
    if (cat === category || k === keyId) {
      targetSlot = k;
      break;
    }
  }

  activeCockpitSlot = targetSlot;

  document.querySelectorAll(".cockpit-key-btn").forEach(btn => {
    btn.classList.toggle("active", btn.getAttribute("data-slot") === targetSlot);
  });

  document.querySelectorAll(".slot-panel").forEach(panel => {
    panel.classList.toggle("active", panel.id === `slot-panel-${targetSlot}`);
  });
}

function initCockpitWidget() {
  // Wire 5-key cockpit selector buttons
  document.querySelectorAll(".cockpit-key-btn").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      const slot = btn.getAttribute("data-slot");
      selectCockpitSlot(slot, true);
    });
  });

  // Wire quick profile switcher pills inside slot C
  document.querySelectorAll(".profile-pill").forEach(pill => {
    pill.addEventListener("click", (e) => {
      e.stopPropagation();
      const idx = parseInt(pill.getAttribute("data-index"), 10);
      selectCockpitSlot("c", false);
      activateCategory("chrome", idx, String(idx + 1), true);
    });
  });

  const popupCard = document.getElementById("chrome-popup-card");
  if (popupCard) {
    popupCard.addEventListener("click", () => {
      selectCockpitSlot("c", false);
      const nextIdx = (activeIndex + 1) % PROFILES.length;
      activateCategory("chrome", nextIdx, String(nextIdx + 1), true);
    });
  }

  updateChromeProfileWidget(activeIndex);
}

function initChromeProfileWidget() {
  initCockpitWidget();
}

function updateChromeProfileWidget(profileIdx = 0) {
  const profile = PROFILES[profileIdx] || PROFILES[0];
  const activeAvatar = document.getElementById("chrome-active-avatar");
  const activeName = document.getElementById("chrome-active-name");
  const activeEmail = document.getElementById("chrome-active-email");
  const activeStatus = document.getElementById("chrome-active-status-text");
  const windowCount = document.getElementById("chrome-window-count");

  if (activeAvatar) {
    if (profile.avatarImg) {
      activeAvatar.style.background = "transparent";
      activeAvatar.innerHTML = `<img src="${profile.avatarImg}" class="chrome-active-avatar-img" alt="${profile.name}">`;
    } else {
      activeAvatar.style.background = profile.avatarBg;
      activeAvatar.innerHTML = `<span>${profile.avatarEmoji}</span>`;
    }
  }
  if (activeName) activeName.textContent = profile.headerName || profile.name;
  if (activeEmail) activeEmail.textContent = profile.email;
  if (activeStatus) activeStatus.textContent = `Sync Is On • ⚡ 0ms Raised`;
  if (windowCount) windowCount.textContent = `${profile.windows} ${profile.windows === 1 ? "window" : "windows"}`;
  const tabsCount = document.getElementById("chrome-tabs-count");
  if (tabsCount) tabsCount.textContent = `${profile.tabs.length} tabs`;

  // Update active state in rows
  const rows = document.querySelectorAll(".chrome-profile-row");
  rows.forEach((r, idx) => {
    r.classList.toggle("active", idx === profileIdx);
  });

  // Update active state in quick pills
  document.querySelectorAll(".profile-pill").forEach((pill, idx) => {
    pill.classList.toggle("active", idx === profileIdx);
  });
}

// --------------------------------------------------------------------------
// Category Activation & Tactile Key Depression
// --------------------------------------------------------------------------
let isSquishing = false;
let squishTime = 0;

function triggerHamsterSquish() {
  isSquishing = true;
  squishTime = 0;
  sound.playChime();
}

function activateCategory(category = "chrome", subIndex = null, keyId = null, fromUser = false) {
  if (fromUser) userInteracted = true;
  currentCategory = category;

  if (category === "chrome") {
    if (subIndex !== null && subIndex !== undefined) {
      activeIndex = parseInt(subIndex, 10);
    } else {
      activeIndex = (activeIndex + 1) % PROFILES.length;
    }
  } else if (category === "ai") {
    if (subIndex !== null && subIndex !== undefined) {
      activeIndex = parseInt(subIndex, 10);
    } else {
      activeIndex = (activeIndex + 1) % ANTIGRAVITY_APPS.length;
    }
  }

  sound.playClick();
  triggerHamsterSquish();

  // Physical 3D key depression animation
  const targetKeyId = keyId || (category === "chrome" ? (subIndex !== null ? String(subIndex + 1) : "c") : keyId);
  const keyMesh = keyMeshMap[targetKeyId] || (category === "chrome" ? keyMeshMap["c"] : keyMeshMap[category[0]]);

  if (keyMesh) {
    keyMesh.position.y = keyMesh.userData.basePosY - 0.045;
    if (keyMesh.material && keyMesh.material[2]) {
      keyMesh.material[2].emissiveIntensity = 2.8;
    }

    setTimeout(() => {
      if (keyMesh) {
        keyMesh.position.y = keyMesh.userData.basePosY;
        if (keyMesh.material && keyMesh.material[2]) {
          keyMesh.material[2].emissiveIntensity = 0.35;
        }
      }
    }, 130);
  }

  // Update Live Simulated Native macOS HUD
  updateSimulatedHUD(currentCategory, activeIndex);

  // Update Native Chrome Profile Popup Widget
  updateChromeProfileWidget(activeIndex);

  // Update Cockpit Widget active slot state
  updateCockpitWidget(currentCategory, targetKeyId);

  // Update bottom mnemonic bar active state
  document.querySelectorAll(".mnemonic-pill").forEach((pill) => {
    pill.classList.toggle("active", pill.getAttribute("data-category") === currentCategory);
  });
}

// --------------------------------------------------------------------------
// Mouse & Raycasting Handlers
// --------------------------------------------------------------------------
let hoveredKeyMesh = null;

function onMouseMove(e) {
  const container = document.getElementById("canvas-container");
  if (!container || !camera) return;

  mouseX = (e.clientX / window.innerWidth) * 2 - 1;
  mouseY = -(e.clientY / window.innerHeight) * 2 + 1;
  targetHeadX = mouseX * 0.28;
  targetHeadY = mouseY * 0.18;

  mouseVec.x = mouseX;
  mouseVec.y = mouseY;
  mouseMoved = true;
}

function onPointerDown(e) {
  userInteracted = true;
  mouseVec.x = (e.clientX / window.innerWidth) * 2 - 1;
  mouseVec.y = -(e.clientY / window.innerHeight) * 2 + 1;

  raycaster.setFromCamera(mouseVec, camera);

  // 1. Raycast interactive keys
  const keyHits = raycaster.intersectObjects(interactiveKeyMeshes, true);
  if (keyHits.length > 0) {
    const hitKey = keyHits[0].object;
    const uData = hitKey.userData;
    activateCategory(uData.category, uData.subIndex, uData.keyId, true);
    return;
  }

  // 2. Raycast hamster for squish squeeze
  const hamsterHits = raycaster.intersectObjects(hamsterRoot ? hamsterRoot.children : [], true);
  if (hamsterHits.length > 0) {
    triggerHamsterSquish();
  }
}

function onWindowResize() {
  const w = window.innerWidth;
  const h = window.innerHeight;
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setSize(w, h);
}

// --------------------------------------------------------------------------
// Theme Transition & Dynamic Lighting Engine
// --------------------------------------------------------------------------
function applyTheme(themeName, animate = true, persist = false) {
  currentTheme = themeName;
  const target = THEMES[themeName] || THEMES.dark;

  // Update DOM tokens & persistence
  document.documentElement.setAttribute("data-theme", themeName);
  const themeIcon = document.getElementById("theme-icon");
  if (themeIcon) themeIcon.textContent = themeName === "dark" ? "☀️" : "🌙";
  if (persist) {
    try {
      localStorage.setItem("xomsky_theme_override", themeName);
      localStorage.setItem("xomsky_theme", themeName);
      localStorage.setItem("khomyak_theme", themeName);
    } catch(e) {}
  }

  if (!scene || !floorMat) return;

  if (!animate) {
    scene.background.setHex(target.bg);
    if (scene.fog) {
      scene.fog.color.setHex(target.bg);
      scene.fog.density = target.fogDensity;
    }
    if (ambientLight) {
      ambientLight.color.setHex(target.ambientColor);
      ambientLight.intensity = target.ambientIntensity;
    }
    if (keyLight) {
      keyLight.color.setHex(target.keyLightColor);
      keyLight.intensity = target.keyLightIntensity;
    }
    if (rimLightL) {
      rimLightL.color.setHex(target.rimLColor);
      rimLightL.intensity = target.rimLIntensity;
    }
    if (rimLightR) {
      rimLightR.color.setHex(target.rimRColor);
      rimLightR.intensity = target.rimRIntensity;
    }
    if (fillLight) {
      fillLight.color.setHex(target.fillColor);
      fillLight.intensity = target.fillIntensity;
    }
    if (floorMat) {
      floorMat.color.setHex(target.floorColor);
      floorMat.roughness = target.floorRoughness;
      floorMat.metalness = target.floorMetalness;
    }
    if (panelMat) panelMat.color.setHex(target.panelColor);
    if (pillarMat) {
      pillarMat.color.setHex(target.pillarColor);
      pillarMat.roughness = target.pillarRoughness;
      pillarMat.metalness = target.pillarMetalness;
    }
    if (chassisMat) {
      chassisMat.color.setHex(target.chassisColor);
      chassisMat.roughness = target.chassisRoughness;
      chassisMat.metalness = target.chassisMetalness;
    }
    if (plateMat) {
      plateMat.color.setHex(target.plateColor);
      plateMat.roughness = target.plateRoughness;
      plateMat.metalness = target.plateMetalness;
    }
    if (glowStripMat) glowStripMat.color.setHex(target.glowStripColor);
    return;
  }

  // Animate lerp transition
  themeTransition.from = {
    bgColor: scene.background.clone(),
    fogDensity: scene.fog ? scene.fog.density : target.fogDensity,
    ambientColor: ambientLight ? ambientLight.color.clone() : new THREE.Color(target.ambientColor),
    ambientIntensity: ambientLight ? ambientLight.intensity : target.ambientIntensity,
    keyLightColor: keyLight ? keyLight.color.clone() : new THREE.Color(target.keyLightColor),
    keyLightIntensity: keyLight ? keyLight.intensity : target.keyLightIntensity,
    rimLColor: rimLightL ? rimLightL.color.clone() : new THREE.Color(target.rimLColor),
    rimLIntensity: rimLightL ? rimLightL.intensity : target.rimLIntensity,
    rimRColor: rimLightR ? rimLightR.color.clone() : new THREE.Color(target.rimRColor),
    rimRIntensity: rimLightR ? rimLightR.intensity : target.rimRIntensity,
    fillColor: fillLight ? fillLight.color.clone() : new THREE.Color(target.fillColor),
    fillIntensity: fillLight ? fillLight.intensity : target.fillIntensity,
    floorColor: floorMat ? floorMat.color.clone() : new THREE.Color(target.floorColor),
    floorRoughness: floorMat ? floorMat.roughness : target.floorRoughness,
    floorMetalness: floorMat ? floorMat.metalness : target.floorMetalness,
    panelColor: panelMat ? panelMat.color.clone() : new THREE.Color(target.panelColor),
    pillarColor: pillarMat ? pillarMat.color.clone() : new THREE.Color(target.pillarColor),
    pillarRoughness: pillarMat ? pillarMat.roughness : target.pillarRoughness,
    pillarMetalness: pillarMat ? pillarMat.metalness : target.pillarMetalness,
    chassisColor: chassisMat ? chassisMat.color.clone() : new THREE.Color(target.chassisColor),
    chassisRoughness: chassisMat ? chassisMat.roughness : target.chassisRoughness,
    chassisMetalness: chassisMat ? chassisMat.metalness : target.chassisMetalness,
    plateColor: plateMat ? plateMat.color.clone() : new THREE.Color(target.plateColor),
    plateRoughness: plateMat ? plateMat.roughness : target.plateRoughness,
    plateMetalness: plateMat ? plateMat.metalness : target.plateMetalness
  };

  themeTransition.to = {
    bgColor: new THREE.Color(target.bg),
    fogDensity: target.fogDensity,
    ambientColor: new THREE.Color(target.ambientColor),
    ambientIntensity: target.ambientIntensity,
    keyLightColor: new THREE.Color(target.keyLightColor),
    keyLightIntensity: target.keyLightIntensity,
    rimLColor: new THREE.Color(target.rimLColor),
    rimLIntensity: target.rimLIntensity,
    rimRColor: new THREE.Color(target.rimRColor),
    rimRIntensity: target.rimRIntensity,
    fillColor: new THREE.Color(target.fillColor),
    fillIntensity: target.fillIntensity,
    floorColor: new THREE.Color(target.floorColor),
    floorRoughness: target.floorRoughness,
    floorMetalness: target.floorMetalness,
    panelColor: new THREE.Color(target.panelColor),
    pillarColor: new THREE.Color(target.pillarColor),
    pillarRoughness: target.pillarRoughness,
    pillarMetalness: target.pillarMetalness,
    chassisColor: new THREE.Color(target.chassisColor),
    chassisRoughness: target.chassisRoughness,
    chassisMetalness: target.chassisMetalness,
    plateColor: new THREE.Color(target.plateColor),
    plateRoughness: target.plateRoughness,
    plateMetalness: target.plateMetalness
  };

  themeTransition.progress = 0;
  themeTransition.active = true;
}

function switchTheme(targetTheme = null) {
  const next = targetTheme || (currentTheme === "dark" ? "light" : "dark");
  sound.playRelayClick(next === "dark");
  applyTheme(next, true, true);
}

// --------------------------------------------------------------------------
// Animation Loop
// --------------------------------------------------------------------------
let clock = new THREE.Clock();

function animate() {
  requestAnimationFrame(animate);

  const delta = clock.getDelta();
  const time = clock.getElapsedTime();

  controls.update();

  // Hover Raycasting (only when mouse has moved)
  if (camera && mouseVec && mouseMoved) {
    mouseMoved = false;
    const container = document.getElementById("canvas-container");
    raycaster.setFromCamera(mouseVec, camera);
    const keyHits = raycaster.intersectObjects(interactiveKeyMeshes, true);

    if (keyHits.length > 0) {
      if (container && container.style.cursor !== "pointer") container.style.cursor = "pointer";
      const hitKey = keyHits[0].object;
      if (hoveredKeyMesh !== hitKey) {
        if (hoveredKeyMesh && hoveredKeyMesh.material && hoveredKeyMesh.material[2]) {
          hoveredKeyMesh.material[2].emissiveIntensity = 0.35;
        }
        hoveredKeyMesh = hitKey;
        if (hoveredKeyMesh.material && hoveredKeyMesh.material[2]) {
          hoveredKeyMesh.material[2].emissiveIntensity = 1.2;
        }
      }
    } else {
      if (container && container.style.cursor !== "grab") container.style.cursor = "grab";
      if (hoveredKeyMesh && hoveredKeyMesh.material && hoveredKeyMesh.material[2]) {
        hoveredKeyMesh.material[2].emissiveIntensity = 0.35;
        hoveredKeyMesh = null;
      }
    }
  }

  // Dynamic Theme Transition Interpolation (Cubic Ease)
  if (themeTransition.active) {
    themeTransition.progress += delta / themeTransition.duration;
    const p = Math.min(1.0, themeTransition.progress);
    const ease = p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2;

    const f = themeTransition.from;
    const t = themeTransition.to;

    scene.background.copy(f.bgColor).lerp(t.bgColor, ease);
    if (scene.fog) {
      scene.fog.color.copy(f.bgColor).lerp(t.bgColor, ease);
      scene.fog.density = THREE.MathUtils.lerp(f.fogDensity, t.fogDensity, ease);
    }
    if (ambientLight) {
      ambientLight.color.copy(f.ambientColor).lerp(t.ambientColor, ease);
      ambientLight.intensity = THREE.MathUtils.lerp(f.ambientIntensity, t.ambientIntensity, ease);
    }
    if (keyLight) {
      keyLight.color.copy(f.keyLightColor).lerp(t.keyLightColor, ease);
      keyLight.intensity = THREE.MathUtils.lerp(f.keyLightIntensity, t.keyLightIntensity, ease);
    }
    if (rimLightL) {
      rimLightL.color.copy(f.rimLColor).lerp(t.rimLColor, ease);
      rimLightL.intensity = THREE.MathUtils.lerp(f.rimLIntensity, t.rimLIntensity, ease);
    }
    if (rimLightR) {
      rimLightR.color.copy(f.rimRColor).lerp(t.rimRColor, ease);
      rimLightR.intensity = THREE.MathUtils.lerp(f.rimRIntensity, t.rimRIntensity, ease);
    }
    if (fillLight) {
      fillLight.color.copy(f.fillColor).lerp(t.fillColor, ease);
      fillLight.intensity = THREE.MathUtils.lerp(f.fillIntensity, t.fillIntensity, ease);
    }
    if (floorMat) {
      floorMat.color.copy(f.floorColor).lerp(t.floorColor, ease);
      floorMat.roughness = THREE.MathUtils.lerp(f.floorRoughness, t.floorRoughness, ease);
      floorMat.metalness = THREE.MathUtils.lerp(f.floorMetalness, t.floorMetalness, ease);
    }
    if (panelMat) {
      panelMat.color.copy(f.panelColor).lerp(t.panelColor, ease);
    }
    if (pillarMat) {
      pillarMat.color.copy(f.pillarColor).lerp(t.pillarColor, ease);
      pillarMat.roughness = THREE.MathUtils.lerp(f.pillarRoughness, t.pillarRoughness, ease);
      pillarMat.metalness = THREE.MathUtils.lerp(f.pillarMetalness, t.pillarMetalness, ease);
    }
    if (chassisMat) {
      chassisMat.color.copy(f.chassisColor).lerp(t.chassisColor, ease);
      chassisMat.roughness = THREE.MathUtils.lerp(f.chassisRoughness, t.chassisRoughness, ease);
      chassisMat.metalness = THREE.MathUtils.lerp(f.chassisMetalness, t.chassisMetalness, ease);
    }
    if (plateMat) {
      plateMat.color.copy(f.plateColor).lerp(t.plateColor, ease);
      plateMat.roughness = THREE.MathUtils.lerp(f.plateRoughness, t.plateRoughness, ease);
      plateMat.metalness = THREE.MathUtils.lerp(f.plateMetalness, t.plateMetalness, ease);
    }

    if (p >= 1.0) {
      themeTransition.active = false;
    }
  }

  // Giant Hamster Breathing Motion (Calm, deep, smooth liminal breathing)
  const BASE_SCALE = 0.68;
  const BASE_Y = -0.45;
  const breath = Math.sin(time * 1.2) * 0.005;
  if (!isSquishing && hamsterRoot) {
    hamsterRoot.scale.set(BASE_SCALE + breath * 0.03, BASE_SCALE - breath * 0.04, BASE_SCALE + breath * 0.03);
  }

  // Smooth Camera Perspective Glide (Switch between Butt View & Front View)
  if (isCamTransitioning && camera && controls) {
    camera.position.lerp(targetCamPos, delta * 5.5);
    controls.target.lerp(targetCamLook, delta * 5.5);
    controls.update();
    if (camera.position.distanceTo(targetCamPos) < 0.04) {
      camera.position.copy(targetCamPos);
      controls.target.copy(targetCamLook);
      controls.update();
      isCamTransitioning = false;
    }
  }

  // Soft & Gentle Tactile Squish / Micro-Hop on Keypress
  if (isSquishing && cheeksGroup) {
    squishTime += delta * 8.0;
    const factor = Math.sin(squishTime) * Math.exp(-squishTime * 0.50);
    cheeksGroup.scale.set(1.0 + factor * 0.16, 1.0 - factor * 0.10, 1.0 + factor * 0.12);
    if (tailMesh) {
      tailMesh.rotation.z = Math.sin(squishTime * 3.0) * factor * 0.35; // cute tail wag
    }
    if (hamsterRoot) {
      hamsterRoot.rotation.z = Math.sin(squishTime * 1.5) * factor * 0.035; // gentle, cute wobble
      hamsterRoot.position.y = BASE_Y + Math.abs(Math.sin(squishTime * 1.2)) * factor * 0.05; // subtle micro-hop
    }
    if (squishTime > Math.PI * 2.0) {
      isSquishing = false;
      cheeksGroup.scale.set(1, 1, 1);
      if (tailMesh) tailMesh.rotation.z = 0;
      if (hamsterRoot) {
        hamsterRoot.rotation.z = 0;
        hamsterRoot.position.y = BASE_Y;
      }
    }
  }

  // Rare, gentle nose micro-twitch
  if (snoutGroup) {
    const twitch = Math.sin(time * 6.0) * 0.003 * (Math.sin(time * 0.3) > 0.85 ? 1 : 0);
    snoutGroup.position.y = 0.96 + twitch;
    if (whiskersGroup) whiskersGroup.rotation.z = twitch * 0.5;
  }

  // Rare, gentle ear micro-twitch
  if (leftEarGroup && rightEarGroup) {
    const earTwitch = Math.sin(time * 5.0) * 0.012 * (Math.sin(time * 0.25) > 0.90 ? 1 : 0);
    leftEarGroup.rotation.z = 0.25 + earTwitch;
    rightEarGroup.rotation.z = -0.25 - earTwitch;
  }

  // Eyes Cursor Tracking & Blinking
  if (eyesGroup) {
    eyesGroup.rotation.y += (targetHeadX - eyesGroup.rotation.y) * 0.08;
    eyesGroup.rotation.x += (-targetHeadY - eyesGroup.rotation.x) * 0.08;

    const isBlink = ((time + 2.0) % 4.0) < 0.12;
    const blinkScale = isBlink ? 0.05 : 1.0;
    eyeLeft.scale.y = blinkScale;
    eyeRight.scale.y = blinkScale;
  }

  renderer.render(scene, camera);
}

// --------------------------------------------------------------------------
// Initialization
// --------------------------------------------------------------------------
document.addEventListener("DOMContentLoaded", () => {
  initThreeJS();
  applyTheme(currentTheme, false, false);

  // Auto-adapt to OS system theme changes if user hasn't set an explicit manual override
  if (window.matchMedia) {
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
      try {
        const hasOverride = localStorage.getItem("xomsky_theme_override");
        if (!hasOverride) {
          applyTheme(e.matches ? "dark" : "light", true, false);
        }
      } catch (err) {
        applyTheme(e.matches ? "dark" : "light", true, false);
      }
    });
  }

  // Theme Toggle Button
  const themeBtn = document.getElementById("theme-toggle");
  if (themeBtn) {
    themeBtn.addEventListener("click", () => {
      switchTheme();
    });
  }

  // Sound Toggle Button
  const soundBtn = document.getElementById("sound-toggle");
  if (soundBtn) {
    soundBtn.addEventListener("click", () => {
      const isAudible = sound.toggle();
      const soundIcon = document.getElementById("sound-icon");
      if (soundIcon) soundIcon.textContent = isAudible ? "🔊" : "🔇";
      if (isAudible) sound.playClick();
    });
  }

  // 1-Click Terminal Install Copy
  const copyInstallBtn = document.getElementById("copy-install-btn");
  const installCmd = document.getElementById("install-cmd");
  if (copyInstallBtn && installCmd) {
    const copyAction = () => {
      const text = installCmd.textContent.trim();
      const onCopied = () => {
        const textSpan = copyInstallBtn.querySelector(".copy-text");
        if (textSpan) textSpan.textContent = "Copied! ✓";
        copyInstallBtn.classList.add("copied");
        sound.playChime();
        setTimeout(() => {
          if (textSpan) textSpan.textContent = "Copy";
          copyInstallBtn.classList.remove("copied");
        }, 2200);
      };

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(onCopied).catch(() => {
          const ta = document.createElement("textarea");
          ta.value = text;
          document.body.appendChild(ta);
          ta.select();
          document.execCommand("copy");
          document.body.removeChild(ta);
          onCopied();
        });
      } else {
        const ta = document.createElement("textarea");
        ta.value = text;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand("copy");
        document.body.removeChild(ta);
        onCopied();
      }
    };

    copyInstallBtn.addEventListener("click", copyAction);
    installCmd.addEventListener("click", copyAction);
  }

  // Card Elements & Segmented Toggles (Live HUD, Pricing, Paradox)
  const hudCard = document.getElementById("native-mac-hud");
  const hudToggle = document.getElementById("hud-toggle");

  const pricingCard = document.getElementById("pricing-card");
  const pricingToggle = document.getElementById("pricing-toggle");
  const pricingClose = document.getElementById("pricing-close");
  const heroPricingTrigger = document.getElementById("hero-pricing-trigger");

  const paradoxCard = document.getElementById("paradox-card");
  const paradoxToggle = document.getElementById("paradox-toggle");
  const paradoxClose = document.getElementById("paradox-close");

  function showCard(target) {
    // target can be 'hud', 'pricing', 'paradox', or 'none'
    if (hudCard) {
      hudCard.classList.toggle("minimized", target !== "hud");
      if (hudToggle) hudToggle.classList.toggle("active", target === "hud");
    }
    if (pricingCard) {
      pricingCard.classList.toggle("minimized", target !== "pricing");
      if (pricingToggle) pricingToggle.classList.toggle("active", target === "pricing");
    }
    if (paradoxCard) {
      paradoxCard.classList.toggle("minimized", target !== "paradox");
      if (paradoxToggle) paradoxToggle.classList.toggle("active", target === "paradox");
    }
    sound.playClick();
  }

  if (hudToggle) {
    hudToggle.addEventListener("click", () => {
      const isCurrentlyOpen = hudCard && !hudCard.classList.contains("minimized");
      showCard(isCurrentlyOpen ? "none" : "hud");
    });
  }

  if (pricingToggle) {
    pricingToggle.addEventListener("click", () => {
      const isCurrentlyOpen = pricingCard && !pricingCard.classList.contains("minimized");
      showCard(isCurrentlyOpen ? "hud" : "pricing");
    });
  }
  if (heroPricingTrigger) {
    heroPricingTrigger.addEventListener("click", () => {
      showCard("pricing");
    });
  }
  if (pricingClose) {
    pricingClose.addEventListener("click", () => showCard("hud"));
  }

  if (paradoxToggle) {
    paradoxToggle.addEventListener("click", () => {
      const isCurrentlyOpen = paradoxCard && !paradoxCard.classList.contains("minimized");
      showCard(isCurrentlyOpen ? "hud" : "paradox");
    });
  }
  if (paradoxClose) {
    paradoxClose.addEventListener("click", () => showCard("hud"));
  }

  // Initialize Simulated Native macOS HUD
  const params = new URLSearchParams(window.location.search);
  const initialCategory = params.get("category") || "chrome";
  const initialIndex = parseInt(params.get("index") || "0", 10);
  updateSimulatedHUD(initialCategory, initialIndex);

  // Live Native HUD: Profile Slot Clicks (Matching MinimalHUDWindow.swift)
  document.querySelectorAll(".hud-slot-item").forEach((pill) => {
    pill.addEventListener("click", () => {
      const idx = parseInt(pill.getAttribute("data-index"), 10);
      activateCategory("chrome", idx, String(idx + 1), true);
    });
  });

  // Initialize Native Google Chrome Profile Popup Widget
  initChromeProfileWidget();

  // Camera Perspective Toggle (🍑 Butt View vs 🐹 Face View)
  const camBtn = document.getElementById("cam-view-btn");
  if (camBtn) {
    camBtn.addEventListener("click", toggleCameraView);
  }
  updateCamBtnLabel();

  // Spotlight Paradox: Simulate Profile 4 Jump Button
  const simProfile4Btn = document.getElementById("simulate-profile4-btn");
  if (simProfile4Btn) {
    simProfile4Btn.addEventListener("click", () => {
      activateCategory("chrome", 3, "4", true);
    });
  }

  // Mnemonic Thought-to-Key Interactive Pills
  document.querySelectorAll(".mnemonic-pill").forEach((pill) => {
    pill.addEventListener("click", () => {
      const cat = pill.getAttribute("data-category");
      const key = pill.getAttribute("data-key");
      activateCategory(cat, 0, key, true);
    });
  });

  // Keyboard Navigation: [V], [C], [1..4], [T], [I], [A], [N], [Space], [M]
  window.addEventListener("keydown", (e) => {
    if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") return;

    const key = e.key.toLowerCase();
    if (key === "m") {
      switchTheme();
    } else if (key === "v") {
      toggleCameraView();
    } else if (key === "c" || key === " ") {
      e.preventDefault();
      selectCockpitSlot("c", false);
      activateCategory("chrome", (activeIndex + 1) % PROFILES.length, "c", true);
    } else if (["1", "2", "3", "4"].includes(key)) {
      selectCockpitSlot("c", false);
      activateCategory("chrome", parseInt(key, 10) - 1, key, true);
    } else if (key === "t") {
      selectCockpitSlot("t", true);
    } else if (key === "i") {
      selectCockpitSlot("i", true);
    } else if (key === "a") {
      selectCockpitSlot("a", true);
    } else if (key === "n") {
      selectCockpitSlot("n", true);
    } else if (key === "capslock") {
      activateCategory("caps", 0, "caps", true);
    }
  });
});
