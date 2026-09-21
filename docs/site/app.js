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
const PROFILES = [
  {
    name: "Igor",
    icon: "💼",
    initial: "I",
    space: "Space 1",
    tabs: "GitHub • Linear • Specs",
    url: "https://linear.app/team-core",
    color: "#F43F5E"
  },
  {
    name: "Nastya",
    icon: "🎨",
    initial: "N",
    space: "Space 2",
    tabs: "Figma • Bauhaus Mascot • Lofi",
    url: "https://figma.com",
    color: "#10B981"
  },
  {
    name: "Al11",
    icon: "🔥",
    initial: "A",
    space: "Space 3",
    tabs: "GCP Console • Phoenix Traces",
    url: "https://console.cloud.google.com",
    color: "#F59E0B"
  },
  {
    name: "GCP Trial",
    icon: "🕶️",
    initial: "G",
    space: "Space 4",
    tabs: "Vertex AI • Cloud Billing",
    url: "https://console.cloud.google.com/vertex-ai",
    color: "#06B6D4"
  }
];

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
let whiskersGroup;
let keyboardGroup;
let interactiveKeyMeshes = [];
let keyMeshMap = {};
let portalWindowMesh, portalCanvas, portalCtx, portalTexture;
let activePortalScale = 1.0;

let mouseX = 0, mouseY = 0;
let targetHeadX = 0, targetHeadY = 0;
let raycaster, mouseVec;

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
    chassisColor: 0x161C28,
    chassisRoughness: 0.32,
    chassisMetalness: 0.82,
    plateColor: 0x0F1420,
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

  // Camera: Placed directly facing the giant hamster face and cheeks
  camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 1000);
  camera.position.set(2.45, 1.95, 7.2);

  // Renderer
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: "high-performance" });
  renderer.setSize(width, height);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.05;
  container.appendChild(renderer.domElement);

  // OrbitControls
  controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.06;
  controls.maxPolarAngle = Math.PI / 2 - 0.02;
  controls.minDistance = 2.4;
  controls.maxDistance = 8.0;
  controls.target.set(0, 1.10, 0); // Directly look at the cute hamster face!

  // Raycasting
  raycaster = new THREE.Raycaster();
  mouseVec = new THREE.Vector2();

  // Build Scene
  buildBrightLiminalEnvironment();
  buildGiantRealisticHamster();
  buildMechanicalKeyboardDeck();
  buildFlankingChromeWindows();

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

  // Architectural Pillars in Haze
  const pillarGeo = new THREE.BoxGeometry(2.0, 20, 2.0);
  pillarMat = new THREE.MeshStandardMaterial({
    color: t.pillarColor,
    roughness: t.pillarRoughness,
    metalness: t.pillarMetalness
  });
  pillarMeshes = [];
  [
    [-12, 8, -14], [12, 8, -14],
    [-18, 8, -6], [18, 8, -6]
  ].forEach(pos => {
    const pillar = new THREE.Mesh(pillarGeo, pillarMat);
    pillar.position.set(...pos);
    scene.add(pillar);
    pillarMeshes.push(pillar);
  });
}

// --------------------------------------------------------------------------
// Giant Geometric Bauhaus Hamster with Green LED Keycap (Liminal Experience)
// --------------------------------------------------------------------------
function buildGiantRealisticHamster() {
  hamsterRoot = new THREE.Group();
  hamsterRoot.position.set(0, 0.05, 0);
  hamsterRoot.scale.set(1.4, 1.4, 1.4);

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
  const eyeRingOuterGeo = new THREE.TorusGeometry(0.35, 0.016, 16, 64);
  const eyeRingInnerGeo = new THREE.TorusGeometry(0.27, 0.015, 16, 64);
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
  // Front Paws: resting gracefully above keyboard deck
  const leftPawGroup = new THREE.Group();
  leftPawGroup.position.set(-0.46, 0.18, 0.96);
  leftPawGroup.rotation.x = 0.22;
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
  rightPawGroup.position.set(0.46, 0.18, 0.96);
  rightPawGroup.rotation.x = 0.22;
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

  // 6. Soft Hind Feet Resting on Marble Floor
  const footGeo = new THREE.SphereGeometry(0.24, 20, 20);
  footGeo.scale(1.2, 0.5, 1.5);
  const leftFoot = new THREE.Mesh(footGeo, bauhausYellowMat);
  leftFoot.position.set(-0.78, -0.12, 0.35);
  hamsterRoot.add(leftFoot);

  const rightFoot = new THREE.Mesh(footGeo, bauhausYellowMat);
  rightFoot.position.set(0.78, -0.12, 0.35);
  hamsterRoot.add(rightFoot);

  scene.add(hamsterRoot);
}

// --------------------------------------------------------------------------
// 3D Mechanical Keyboard Command Deck (60% Layout with Highlighted Keys)
// --------------------------------------------------------------------------
function createKeycapTexture(label, isInteractive, accentColor, hasLed, isCaps) {
  const canvas = document.createElement("canvas");
  canvas.width = 256;
  canvas.height = 256;
  const ctx = canvas.getContext("2d");

  // Keycap base gradient
  const bgGrad = ctx.createLinearGradient(0, 0, 0, 256);
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
  ctx.roundRect(8, 8, 240, 240, 28);
  ctx.fill();

  // Chamfered Inner Bevel Border
  ctx.strokeStyle = isInteractive ? (accentColor || "#38BDF8") : "rgba(255, 255, 255, 0.12)";
  ctx.lineWidth = isInteractive ? 8 : 4;
  ctx.stroke();

  // Top Inset Highlight
  ctx.strokeStyle = "rgba(255, 255, 255, 0.2)";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.roundRect(16, 16, 224, 224, 20);
  ctx.stroke();

  // Glowing LED for Caps Lock
  if (hasLed) {
    const ledGrad = ctx.createRadialGradient(48, 48, 2, 48, 48, 24);
    ledGrad.addColorStop(0, "#86EFAC");
    ledGrad.addColorStop(0.4, "rgba(34, 197, 94, 0.9)");
    ledGrad.addColorStop(1, "rgba(34, 197, 94, 0)");
    ctx.fillStyle = ledGrad;
    ctx.beginPath();
    ctx.arc(48, 48, 24, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = "#22C55E";
    ctx.beginPath();
    ctx.arc(48, 48, 8, 0, Math.PI * 2);
    ctx.fill();
  }

  // Golden Upward Arrow for Caps Lock
  if (isCaps) {
    ctx.save();
    ctx.translate(128, 100);
    ctx.beginPath();
    ctx.moveTo(0, -42);
    ctx.lineTo(36, -8);
    ctx.lineTo(16, -8);
    ctx.lineTo(16, 32);
    ctx.lineTo(-16, 32);
    ctx.lineTo(-16, -8);
    ctx.lineTo(-36, -8);
    ctx.closePath();
    ctx.fillStyle = "#F59E0B";
    ctx.fill();
    ctx.strokeStyle = "#0F172A";
    ctx.lineWidth = 5;
    ctx.stroke();
    ctx.restore();

    ctx.fillStyle = "#FFFFFF";
    ctx.font = "bold 26px -apple-system, BlinkMacSystemFont, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("caps", 128, 185);
  } else {
    // Standard or Highlighted Legend
    ctx.fillStyle = isInteractive ? (accentColor || "#FFFFFF") : "#94A3B8";
    ctx.font = isInteractive ? "bold 72px -apple-system, BlinkMacSystemFont, monospace" : "bold 56px -apple-system, BlinkMacSystemFont, monospace";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.shadowColor = isInteractive ? (accentColor || "#38BDF8") : "rgba(0,0,0,0.5)";
    ctx.shadowBlur = isInteractive ? 14 : 4;
    ctx.fillText(label, 128, 128);
  }

  const texture = new THREE.CanvasTexture(canvas);
  texture.anisotropy = 4;
  return texture;
}

function buildMechanicalKeyboardDeck() {
  keyboardGroup = new THREE.Group();
  keyboardGroup.position.set(0, -0.05, 1.60);
  keyboardGroup.rotation.y = 0; // Strictly oriented facing the human user (Spacebar in front, Esc top-left)
  keyboardGroup.rotation.x = 0.12; // ~7° natural ergonomic tilt facing toward the user (back propped up, spacebar low)

  const t = THEMES[currentTheme] || THEMES.dark;

  // 1. Keyboard Chassis (Dark Anodized Aluminum / Slate)
  const chassisGeo = new THREE.BoxGeometry(2.78, 0.11, 1.10);
  chassisMat = new THREE.MeshStandardMaterial({
    color: t.chassisColor,
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
    color: t.plateColor,
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
// Multi-Category 3D Portal Canvas Renderer
// --------------------------------------------------------------------------
function drawSquircleBadge(ctx, x, y, size, icon, bgColor) {
  ctx.save();
  ctx.fillStyle = bgColor || "#FFFFFF";
  ctx.shadowColor = "rgba(0, 0, 0, 0.4)";
  ctx.shadowBlur = 14;
  ctx.shadowOffsetY = 4;
  ctx.beginPath();
  ctx.roundRect(x, y, size, size, size * 0.24);
  ctx.fill();
  ctx.strokeStyle = "rgba(255, 255, 255, 0.2)";
  ctx.lineWidth = 2;
  ctx.stroke();

  ctx.fillStyle = "#0F172A";
  ctx.font = `${Math.floor(size * 0.52)}px -apple-system, sans-serif`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(icon, x + size / 2, y + size / 2);
  ctx.restore();
}

function createPortalCanvas(category = "chrome", selectedIdx = 0) {
  if (!portalCanvas) {
    portalCanvas = document.createElement("canvas");
    portalCanvas.width = 600;
    portalCanvas.height = 520;
    portalCtx = portalCanvas.getContext("2d");
  }
  const ctx = portalCtx;
  ctx.clearRect(0, 0, 600, 520);

  // 1. Outer Frosted Glass Bezel (High-contrast deep obsidian)
  ctx.save();
  ctx.fillStyle = "#12141A";
  ctx.beginPath();
  ctx.roundRect(10, 10, 580, 500, 36);
  ctx.fill();
  ctx.strokeStyle = "rgba(255, 255, 255, 0.24)";
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.restore();

  // 2. Inner Royal Slate Card
  const cardX = 26;
  const cardY = 26;
  const cardW = 548;
  const cardH = 468;
  const cardR = 24;

  const catData = CATEGORY_DATA[category] || CATEGORY_DATA.chrome;

  ctx.save();
  ctx.fillStyle = "#162032";
  ctx.beginPath();
  ctx.roundRect(cardX, cardY, cardW, cardH, cardR);
  ctx.fill();
  ctx.strokeStyle = catData.color || "#38BDF8";
  ctx.lineWidth = 3;
  ctx.stroke();
  ctx.restore();

  // 3. Header & Icon
  if (category === "chrome") {
    drawSquircleBadge(ctx, 248, 48, 104, "🌐", "#FFFFFF");

    ctx.save();
    ctx.fillStyle = "#FFFFFF";
    ctx.font = "bold 26px -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("Google Chrome", 300, 184);
    ctx.restore();

    // Horizontal Profile Avatars Row
    const activeProfile = PROFILES[selectedIdx] || PROFILES[0];
    const avatarSpacing = 98;
    const totalW = (PROFILES.length - 1) * avatarSpacing;
    const startX = 300 - totalW / 2;
    const avatarY = 256;
    const avatarRadius = 28;

    PROFILES.forEach((p, idx) => {
      const cx = startX + idx * avatarSpacing;
      const isSelected = idx === selectedIdx;

      if (isSelected) {
        ctx.save();
        ctx.strokeStyle = "#38BDF8";
        ctx.lineWidth = 4.5;
        ctx.shadowColor = "#38BDF8";
        ctx.shadowBlur = 20;
        ctx.beginPath();
        ctx.arc(cx, avatarY, avatarRadius + 10, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
      }

      ctx.save();
      ctx.fillStyle = p.color || "#0284C7";
      ctx.beginPath();
      ctx.arc(cx, avatarY, avatarRadius, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = "#FFFFFF";
      ctx.lineWidth = 2;
      ctx.stroke();

      ctx.fillStyle = "#FFFFFF";
      ctx.font = "bold 22px -apple-system, sans-serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(p.initial || p.name[0], cx, avatarY + 1);
      ctx.restore();

      ctx.save();
      ctx.fillStyle = isSelected ? "#FFFFFF" : "rgba(255, 255, 255, 0.65)";
      ctx.font = isSelected ? "bold 15px -apple-system, sans-serif" : "13px -apple-system, sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(p.name, cx, avatarY + 50);
      ctx.restore();
    });

    // Active Profile Pill Footnote
    ctx.save();
    ctx.fillStyle = "rgba(0, 0, 0, 0.45)";
    ctx.strokeStyle = "rgba(255, 255, 255, 0.16)";
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.roundRect(cardX + 24, 356, cardW - 48, 86, 16);
    ctx.fill();
    ctx.stroke();

    if (selectedIdx === 3) {
      // Profile 4: The Spotlight Paradox Callout!
      ctx.fillStyle = "#38BDF8";
      ctx.font = "bold 15px -apple-system, monospace";
      ctx.textAlign = "center";
      ctx.fillText(`⚡ Profile 4: ${activeProfile.name} • 0ms Instant Warp`, 300, 382);

      ctx.fillStyle = "#F87171";
      ctx.font = "bold 13px -apple-system, sans-serif";
      ctx.fillText(`🚫 Spotlight can't reach profiles (~5.4s manual mouse hunt)`, 300, 406);

      ctx.fillStyle = "#94A3B8";
      ctx.font = "12px -apple-system, sans-serif";
      ctx.fillText(`Xomsky Caps + 4 teleports here in 1 frame (540x faster)`, 300, 426);
    } else {
      ctx.fillStyle = "#7DD3FC";
      ctx.font = "bold 16px -apple-system, monospace";
      ctx.textAlign = "center";
      ctx.fillText(`⚡ Teleport to ${activeProfile.space} • ${activeProfile.name} (Caps + ${selectedIdx + 1})`, 300, 388);

      ctx.fillStyle = "rgba(255, 255, 255, 0.90)";
      ctx.font = "14px -apple-system, sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(activeProfile.tabs, 300, 418);
    }
    ctx.restore();

  } else if (category === "terminal") {
    drawSquircleBadge(ctx, 248, 48, 104, "💻", "#0F172A");

    ctx.save();
    ctx.fillStyle = "#FFFFFF";
    ctx.font = "bold 26px -apple-system, BlinkMacSystemFont, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("Terminal (iTerm2)", 300, 184);
    ctx.restore();

    // Terminal Shell Screen Box
    ctx.save();
    ctx.fillStyle = "#090D16";
    ctx.strokeStyle = "rgba(16, 185, 129, 0.4)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(cardX + 24, 214, cardW - 48, 226, 16);
    ctx.fill();
    ctx.stroke();

    // Traffic light dots
    ctx.fillStyle = "#EF4444"; ctx.beginPath(); ctx.arc(cardX + 44, 234, 6, 0, Math.PI*2); ctx.fill();
    ctx.fillStyle = "#F59E0B"; ctx.beginPath(); ctx.arc(cardX + 62, 234, 6, 0, Math.PI*2); ctx.fill();
    ctx.fillStyle = "#10B981"; ctx.beginPath(); ctx.arc(cardX + 80, 234, 6, 0, Math.PI*2); ctx.fill();

    ctx.fillStyle = "#64748B";
    ctx.font = "11px -apple-system, monospace";
    ctx.fillText("zsh — 80x24 — sub-16ms switch", cardX + 104, 238);

    // Terminal text lines
    ctx.font = "13px ui-monospace, monospace";
    const lines = [
      { text: "$ swift test", color: "#E2E8F0" },
      { text: "✔ Test suite 'ChromeQuickAccessTests' passed (0.042s)", color: "#34D399" },
      { text: "🧠 Mnemonic: Think \"Terminal\" ➔ Press T (Caps + T)", color: "#FCD34D" },
      { text: "igorekishev@MacBook git:(main) ▋", color: "#38BDF8" }
    ];

    lines.forEach((l, i) => {
      ctx.fillStyle = l.color;
      ctx.fillText(l.text, cardX + 44, 276 + i * 32);
    });
    ctx.restore();

  } else if (category === "ide") {
    drawSquircleBadge(ctx, 248, 48, 104, "🛠️", "#1E1B4B");

    ctx.save();
    ctx.fillStyle = "#FFFFFF";
    ctx.font = "bold 26px -apple-system, BlinkMacSystemFont, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("Antigravity IDE", 300, 184);
    ctx.restore();

    // Code Editor Box
    ctx.save();
    ctx.fillStyle = "#0B0F19";
    ctx.strokeStyle = "rgba(99, 102, 241, 0.4)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(cardX + 24, 214, cardW - 48, 226, 16);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#818CF8";
    ctx.font = "12px ui-monospace, monospace";
    ctx.fillText("AppGroupEngine.swift — Swift 6 Native", cardX + 44, 238);

    const codeLines = [
      { num: "42", code: "public static let ide = AppGroupEngine(", color: "#F472B6" },
      { num: "43", code: "    category: \"IDE\", candidates: [\"IntelliJ IDEA\"]", color: "#E2E8F0" },
      { num: "44", code: "    // 🧠 Mnemonic: Think \"IDEA\" ➔ Press I", color: "#FCD34D" },
      { num: "45", code: ") // ⚡ Sub-16ms CGEventTap window focus", color: "#34D399" }
    ];

    codeLines.forEach((l, i) => {
      ctx.fillStyle = "#475569";
      ctx.font = "12px ui-monospace, monospace";
      ctx.fillText(l.num, cardX + 44, 276 + i * 32);

      ctx.fillStyle = l.color;
      ctx.fillText(l.code, cardX + 74, 276 + i * 32);
    });
    ctx.restore();

  } else if (category === "ai") {
    drawSquircleBadge(ctx, 248, 48, 104, "🤖", "#083344");

    ctx.save();
    ctx.fillStyle = "#FFFFFF";
    ctx.font = "bold 26px -apple-system, BlinkMacSystemFont, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("Antigravity AI Agent", 300, 184);
    ctx.restore();

    // AI Chat Card
    ctx.save();
    ctx.fillStyle = "#081B2B";
    ctx.strokeStyle = "rgba(6, 182, 212, 0.45)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(cardX + 24, 214, cardW - 48, 226, 16);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#22D3EE";
    ctx.font = "bold 13px -apple-system, sans-serif";
    ctx.fillText("● AI Agent Stream • Latency: 0ms", cardX + 44, 244);

    ctx.fillStyle = "#E2E8F0";
    ctx.font = "14px -apple-system, sans-serif";
    ctx.fillText("“Zero third-party drivers or background daemons.", cardX + 44, 280);
    ctx.fillText("Your brain thinks 'Agent' ➔ fingers press 'A'.”", cardX + 44, 308);

    ctx.fillStyle = "#FCD34D";
    ctx.font = "bold 13px ui-monospace, monospace";
    ctx.fillText("🧠 Mnemonic: Think \"Agent\" ➔ Press A (Caps + A)", cardX + 44, 350);

    ctx.fillStyle = "#38BDF8";
    ctx.font = "bold 13px ui-monospace, monospace";
    ctx.fillText("Caps-Lock + A ➔ Instant Summon", cardX + 44, 394);
    ctx.restore();

  } else if (category === "notes" || category === "caps") {
    drawSquircleBadge(ctx, 248, 48, 104, "📝", "#451A03");

    ctx.save();
    ctx.fillStyle = "#FFFFFF";
    ctx.font = "bold 26px -apple-system, BlinkMacSystemFont, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("Quick Notes & Scratchpad", 300, 184);
    ctx.restore();

    // Notes Scratchpad Card
    ctx.save();
    ctx.fillStyle = "#1C1917";
    ctx.strokeStyle = "rgba(245, 158, 11, 0.4)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(cardX + 24, 214, cardW - 48, 226, 16);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#FCD34D";
    ctx.font = "bold 13px -apple-system, sans-serif";
    ctx.fillText("📌 Today's Engineering Log", cardX + 44, 244);

    const tasks = [
      { check: "☑", text: "Zero-latency Caps-Lock Hyper Key (0x35)", color: "#34D399" },
      { check: "☑", text: "5-App Toolkit Switcher (C, T, I, A, N)", color: "#34D399" },
      { check: "🧠", text: "Mnemonic: Think \"Notes\" ➔ Press N", color: "#FCD34D" },
      { check: "☐", text: "Ship Xomsky v1.0.0 Universal DMG", color: "#38BDF8" }
    ];

    tasks.forEach((t, i) => {
      ctx.fillStyle = t.color;
      ctx.font = "14px ui-monospace, monospace";
      ctx.fillText(`${t.check}  ${t.text}`, cardX + 44, 282 + i * 32);
    });
    ctx.restore();
  }

  return portalCanvas;
}

function buildFlankingChromeWindows() {
  createPortalCanvas("chrome", 0);
  portalTexture = new THREE.CanvasTexture(portalCanvas);
  portalTexture.minFilter = THREE.LinearFilter;

  const portalGeo = new THREE.PlaneGeometry(1.42, 1.24);
  const portalMat = new THREE.MeshBasicMaterial({
    map: portalTexture,
    side: THREE.DoubleSide,
    transparent: true,
    fog: false,
    opacity: 1.0
  });

  portalWindowMesh = new THREE.Mesh(portalGeo, portalMat);
  portalWindowMesh.position.set(-2.05, 0.85, 1.6);
  portalWindowMesh.rotation.y = 0.32;
  scene.add(portalWindowMesh);
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

  // Redraw 3D portal window
  createPortalCanvas(currentCategory, activeIndex);
  if (portalTexture) {
    portalTexture.needsUpdate = true;
  }

  // Portal scale bounce
  if (portalWindowMesh) {
    portalWindowMesh.scale.set(1.14, 1.14, 1);
    setTimeout(() => {
      if (portalWindowMesh) portalWindowMesh.scale.set(1.0, 1.0, 1);
    }, 160);
  }
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
  raycaster.setFromCamera(mouseVec, camera);

  // Check hover over interactive keys
  const keyHits = raycaster.intersectObjects(interactiveKeyMeshes, true);

  if (keyHits.length > 0) {
    container.style.cursor = "pointer";
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
    container.style.cursor = "default";
    if (hoveredKeyMesh && hoveredKeyMesh.material && hoveredKeyMesh.material[2]) {
      hoveredKeyMesh.material[2].emissiveIntensity = 0.35;
      hoveredKeyMesh = null;
    }
  }
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

  // Giant Hamster Breathing Motion
  const breath = Math.sin(time * 2.8) * 0.02;
  if (!isSquishing && hamsterRoot) {
    hamsterRoot.scale.set(1.4 + breath * 0.15, 1.4 - breath * 0.25, 1.4 + breath * 0.15);
  }

  // Giant Cheeks Squish Spring Physics
  if (isSquishing && cheeksGroup) {
    squishTime += delta * 14;
    const factor = Math.sin(squishTime) * Math.exp(-squishTime * 0.45);
    cheeksGroup.scale.set(1.0 + factor * 0.4, 1.0 - factor * 0.25, 1.0 + factor * 0.3);
    if (squishTime > Math.PI * 2) {
      isSquishing = false;
      cheeksGroup.scale.set(1, 1, 1);
    }
  }

  // Nose micro-twitch
  if (snoutGroup) {
    const twitch = Math.sin(time * 22.0) * 0.012 * (Math.sin(time * 0.8) > 0.6 ? 1 : 0);
    snoutGroup.position.y = 0.96 + twitch;
    if (whiskersGroup) whiskersGroup.rotation.z = twitch * 1.5;
  }

  // Ear twitch
  if (leftEarGroup && rightEarGroup) {
    const earTwitch = Math.sin(time * 18.0) * 0.035 * (Math.sin(time * 0.5) > 0.8 ? 1 : 0);
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

  // Apply Initial Theme (defaults to user's system theme without saving override)
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

  // Pricing & Tiers Card Toggle & Close (Mutually exclusive with Paradox card)
  const pricingCard = document.getElementById("pricing-card");
  const pricingToggle = document.getElementById("pricing-toggle");
  const pricingClose = document.getElementById("pricing-close");
  const paradoxCard = document.getElementById("paradox-card");
  const paradoxToggle = document.getElementById("paradox-toggle");
  const paradoxClose = document.getElementById("paradox-close");

  if (pricingToggle && pricingCard) {
    pricingToggle.addEventListener("click", () => {
      const willOpen = pricingCard.classList.contains("minimized");
      pricingCard.classList.toggle("minimized");
      if (willOpen && paradoxCard) {
        paradoxCard.classList.add("minimized");
      }
      sound.playClick();
    });
  }

  if (pricingClose && pricingCard) {
    pricingClose.addEventListener("click", () => {
      pricingCard.classList.add("minimized");
      sound.playClick();
    });
  }

  // Spotlight Paradox Card Toggle & Close (Mutually exclusive with Pricing card)
  if (paradoxToggle && paradoxCard) {
    paradoxToggle.addEventListener("click", () => {
      const willOpen = paradoxCard.classList.contains("minimized");
      paradoxCard.classList.toggle("minimized");
      if (willOpen && pricingCard) {
        pricingCard.classList.add("minimized");
      }
      sound.playClick();
    });
  }
  
  if (paradoxClose && paradoxCard) {
    paradoxClose.addEventListener("click", () => {
      paradoxCard.classList.add("minimized");
      sound.playClick();
    });
  }

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

  // Keyboard Navigation: [C], [1..4], [T], [I], [A], [N], [Space], [M]
  window.addEventListener("keydown", (e) => {
    if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") return;

    const key = e.key.toLowerCase();
    if (key === "m") {
      switchTheme();
    } else if (key === "c" || key === " ") {
      e.preventDefault();
      activateCategory("chrome", (activeIndex + 1) % PROFILES.length, "c", true);
    } else if (["1", "2", "3", "4"].includes(key)) {
      activateCategory("chrome", parseInt(key, 10) - 1, key, true);
    } else if (key === "t") {
      activateCategory("terminal", 0, "t", true);
    } else if (key === "i") {
      activateCategory("ide", 0, "i", true);
    } else if (key === "a") {
      activateCategory("ai", 0, "a", true);
    } else if (key === "n") {
      activateCategory("notes", 0, "n", true);
    } else if (key === "capslock") {
      activateCategory("caps", 0, "caps", true);
    }
  });
});
