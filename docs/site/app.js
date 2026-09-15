/**
 * KHOMYAK — Ethereal Bright Liminal 3D Giant Hamster Experience
 * Ultra-clean, photorealistic giant white & soft pinkish hamster filling the screen.
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
}

const sound = new ASMRSoundEngine();

// ==========================================================================
// 2. Profile Data
// ==========================================================================
const PROFILES = [
  {
    name: "Work",
    icon: "💼",
    space: "Space 1",
    tabs: "Linear • GitHub PRs • Figma",
    url: "https://linear.app/team-core",
    color: "#0284C7"
  },
  {
    name: "Personal",
    icon: "🏠",
    space: "Space 2",
    tabs: "YouTube Music • Reddit • X",
    url: "https://youtube.com/watch?v=lofi",
    color: "#E11D48"
  },
  {
    name: "Client",
    icon: "🚀",
    space: "Space 3",
    tabs: "Stripe Billing • AWS • Vercel",
    url: "https://dashboard.stripe.com",
    color: "#059669"
  }
];

let activeIndex = 0;
let userInteracted = false;

// ==========================================================================
// 3. Three.js Scene: Luminous Liminal Space
// ==========================================================================
let scene, camera, renderer, controls;
let hamsterRoot, cheeksGroup, eyesGroup, snoutGroup;
let eyeLeft, eyeRight;
let leftEarGroup, rightEarGroup;
let whiskersGroup, keycapMesh;
let profileWindows = [];

let mouseX = 0, mouseY = 0;
let targetHeadX = 0, targetHeadY = 0;
let raycaster, mouseVec;

function initThreeJS() {
  const container = document.getElementById("canvas-container");
  const width = window.innerWidth;
  const height = window.innerHeight;

  // Scene & Luminous Dreamy Liminal Fog (Light, White, Soft Pinkish)
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0xFDF8FA);
  scene.fog = new THREE.FogExp2(0xFDF8FA, 0.022);

  // Camera: Placed directly facing the giant hamster face and cheeks
  camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 1000);
  camera.position.set(0, 1.35, 6.2);

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
  controls.target.set(0, 1.1, 0); // Directly look at the cute hamster face!

  // Raycasting
  raycaster = new THREE.Raycaster();
  mouseVec = new THREE.Vector2();

  // Build Scene
  buildBrightLiminalEnvironment();
  buildGiantRealisticHamster();
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
  // Luminous Marble Floor
  const floorGeo = new THREE.PlaneGeometry(250, 250);
  const floorMat = new THREE.MeshStandardMaterial({
    color: 0xFFFFFF,
    roughness: 0.15,
    metalness: 0.15
  });
  const floor = new THREE.Mesh(floorGeo, floorMat);
  floor.position.y = -0.6;
  floor.rotation.x = -Math.PI / 2;
  floor.receiveShadow = true;
  scene.add(floor);

  // Overhead Luminous Softbox
  const panelGeo = new THREE.BoxGeometry(12, 0.1, 5);
  const panelMat = new THREE.MeshBasicMaterial({ color: 0xFFFFFF });
  const panel = new THREE.Mesh(panelGeo, panelMat);
  panel.position.set(0, 7.5, 0);
  scene.add(panel);

  // Ambient Light: Bright, Radiant, Zero Dark Shadows
  const ambient = new THREE.AmbientLight(0xFFF0F5, 1.45);
  scene.add(ambient);

  // Studio Key Light
  const keyLight = new THREE.DirectionalLight(0xFFFFFF, 1.9);
  keyLight.position.set(4, 8, 6);
  keyLight.castShadow = true;
  keyLight.shadow.mapSize.width = 2048;
  keyLight.shadow.mapSize.height = 2048;
  keyLight.shadow.bias = -0.0004;
  scene.add(keyLight);

  // Soft Rosy-Pink Rim Light
  const rimLight = new THREE.DirectionalLight(0xF472B6, 1.8);
  rimLight.position.set(-5, 4.5, -5);
  scene.add(rimLight);

  // Front Soft Fill
  const fillLight = new THREE.PointLight(0xFCE7F3, 1.2, 10);
  fillLight.position.set(0, 1.2, 3.2);
  scene.add(fillLight);

  // Pale Liminal Pillars in White Haze
  const pillarGeo = new THREE.BoxGeometry(2.0, 20, 2.0);
  const pillarMat = new THREE.MeshStandardMaterial({ color: 0xFDF2F8, roughness: 0.6 });
  [
    [-12, 8, -14], [12, 8, -14],
    [-18, 8, -6], [18, 8, -6]
  ].forEach(pos => {
    const pillar = new THREE.Mesh(pillarGeo, pillarMat);
    pillar.position.set(...pos);
    scene.add(pillar);
  });
}

// --------------------------------------------------------------------------
// Giant Realistic White-Pinkish Hamster (Filling the Screen!)
// --------------------------------------------------------------------------
function buildGiantRealisticHamster() {
  hamsterRoot = new THREE.Group();
  hamsterRoot.position.set(0, 0, 0);
  hamsterRoot.scale.set(1.5, 1.5, 1.5);

  // Pristine, Soft Pearlescent White Fur Materials
  const whiteFurMat = new THREE.MeshStandardMaterial({
    color: 0xFFF7FA, // Clean pearlescent snow-white with subtle rosy warmth
    roughness: 0.68,
    metalness: 0.02
  });

  const softCheekFurMat = new THREE.MeshStandardMaterial({
    color: 0xFFEDF2, // Delicate rosy blush on cheeks
    roughness: 0.65,
    metalness: 0.02
  });

  const pureWhiteBellyMat = new THREE.MeshStandardMaterial({
    color: 0xFFFFFF,
    roughness: 0.75,
    metalness: 0.01
  });

  const babyPinkSkinMat = new THREE.MeshStandardMaterial({
    color: 0xFB7185, // Soft baby rose pink
    roughness: 0.38,
    metalness: 0.05
  });

  // 1. Giant Chubby Body (Fluffy pear-shaped silhouette)
  const bodyGeo = new THREE.SphereGeometry(1.08, 48, 48);
  bodyGeo.scale(1.22, 1.05, 1.12);
  const bodyMesh = new THREE.Mesh(bodyGeo, whiteFurMat);
  bodyMesh.position.set(0, 0.85, 0);
  bodyMesh.castShadow = true;
  bodyMesh.receiveShadow = true;
  hamsterRoot.add(bodyMesh);

  // Pure White Fluffy Chest Patch
  const bellyGeo = new THREE.SphereGeometry(0.85, 36, 36);
  bellyGeo.scale(0.9, 0.95, 0.45);
  const bellyMesh = new THREE.Mesh(bellyGeo, pureWhiteBellyMat);
  bellyMesh.position.set(0, 0.8, 0.76);
  hamsterRoot.add(bellyMesh);

  // 2. Enormous Puffed Chubby Cheeks (Overflowing the Screen!)
  cheeksGroup = new THREE.Group();
  cheeksGroup.position.set(0, 0.92, 0.6);

  const cheekGeo = new THREE.SphereGeometry(0.64, 36, 36);
  cheekGeo.scale(1.25, 0.92, 0.92);

  const leftCheek = new THREE.Mesh(cheekGeo, softCheekFurMat);
  leftCheek.position.set(-0.76, -0.02, 0);
  leftCheek.castShadow = true;
  cheeksGroup.add(leftCheek);

  const rightCheek = new THREE.Mesh(cheekGeo, softCheekFurMat);
  rightCheek.position.set(0.76, -0.02, 0);
  rightCheek.castShadow = true;
  cheeksGroup.add(rightCheek);

  // Subtle rosy blush decals on cheeks
  const blushGeo = new THREE.CircleGeometry(0.26, 20);
  const blushMat = new THREE.MeshBasicMaterial({ color: 0xFDA4AF, transparent: true, opacity: 0.45 });
  const blushL = new THREE.Mesh(blushGeo, blushMat);
  blushL.position.set(-0.95, -0.02, 0.4);
  blushL.rotation.y = -0.42;
  cheeksGroup.add(blushL);

  const blushR = new THREE.Mesh(blushGeo, blushMat);
  blushR.position.set(0.95, -0.02, 0.4);
  blushR.rotation.y = 0.42;
  cheeksGroup.add(blushR);

  hamsterRoot.add(cheeksGroup);

  // 3. Snout & Cute Baby Pink Button Nose
  snoutGroup = new THREE.Group();
  snoutGroup.position.set(0, 0.95, 1.05);

  const snoutGeo = new THREE.SphereGeometry(0.28, 24, 24);
  snoutGeo.scale(1.05, 0.75, 0.75);
  const snoutMesh = new THREE.Mesh(snoutGeo, pureWhiteBellyMat);
  snoutGroup.add(snoutMesh);

  const noseGeo = new THREE.SphereGeometry(0.09, 20, 20);
  noseGeo.scale(1.25, 0.75, 0.85);
  const noseMesh = new THREE.Mesh(noseGeo, babyPinkSkinMat);
  noseMesh.position.set(0, 0.08, 0.18);
  snoutGroup.add(noseMesh);

  hamsterRoot.add(snoutGroup);

  // 4. Fine Detailed Whiskers Spanning the Screen
  whiskersGroup = new THREE.Group();
  whiskersGroup.position.set(0, 1.0, 1.15);
  const whiskerMat = new THREE.LineBasicMaterial({
    color: 0xFFFFFF,
    transparent: true,
    opacity: 0.85
  });

  for (let i = 0; i < 8; i++) {
    const angle = (i - 3.5) * 0.13;
    // Left Whiskers
    const curveL = new THREE.QuadraticBezierCurve3(
      new THREE.Vector3(-0.16, (i - 4) * 0.02, 0),
      new THREE.Vector3(-0.8, (i - 4) * 0.03, 0.1),
      new THREE.Vector3(-1.6, angle * 0.9 - 0.14, -0.2)
    );
    whiskersGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(curveL.getPoints(14)), whiskerMat));

    // Right Whiskers
    const curveR = new THREE.QuadraticBezierCurve3(
      new THREE.Vector3(0.16, (i - 4) * 0.02, 0),
      new THREE.Vector3(0.8, (i - 4) * 0.03, 0.1),
      new THREE.Vector3(1.6, angle * 0.9 - 0.14, -0.2)
    );
    whiskersGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(curveR.getPoints(14)), whiskerMat));
  }
  hamsterRoot.add(whiskersGroup);

  // 5. Deep Liquid-Dark Obsidian Eyes (High Specular Reflections)
  eyesGroup = new THREE.Group();
  eyesGroup.position.set(0, 1.25, 1.02);

  const eyeMat = new THREE.MeshBasicMaterial({
    color: 0x08080C
  });
  const eyeGeo = new THREE.SphereGeometry(0.18, 32, 32);

  eyeLeft = new THREE.Mesh(eyeGeo, eyeMat);
  eyeLeft.position.set(-0.42, 0, 0);
  eyesGroup.add(eyeLeft);

  eyeRight = new THREE.Mesh(eyeGeo, eyeMat);
  eyeRight.position.set(0.42, 0, 0);
  eyesGroup.add(eyeRight);

  // Big Shiny Specular Highlights
  const glintGeo = new THREE.SphereGeometry(0.055, 16, 16);
  const glintMat = new THREE.MeshBasicMaterial({ color: 0xFFFFFF });
  const glintL = new THREE.Mesh(glintGeo, glintMat);
  glintL.position.set(-0.38, 0.06, 0.15);
  eyesGroup.add(glintL);

  const glintR = new THREE.Mesh(glintGeo, glintMat);
  glintR.position.set(0.46, 0.06, 0.15);
  eyesGroup.add(glintR);

  hamsterRoot.add(eyesGroup);

  // 6. Translucent Pinkish Ears
  const earOuterGeo = new THREE.SphereGeometry(0.32, 24, 24);
  earOuterGeo.scale(0.9, 1.05, 0.35);

  const earInnerGeo = new THREE.SphereGeometry(0.24, 20, 20);
  earInnerGeo.scale(0.85, 0.95, 0.2);

  leftEarGroup = new THREE.Group();
  leftEarGroup.position.set(-0.76, 1.85, -0.05);
  leftEarGroup.rotation.z = 0.38;
  leftEarGroup.rotation.y = -0.22;
  leftEarGroup.add(new THREE.Mesh(earOuterGeo, whiteFurMat));
  const lInner = new THREE.Mesh(earInnerGeo, babyPinkSkinMat);
  lInner.position.z = 0.06;
  leftEarGroup.add(lInner);
  hamsterRoot.add(leftEarGroup);

  rightEarGroup = new THREE.Group();
  rightEarGroup.position.set(0.76, 1.85, -0.05);
  rightEarGroup.rotation.z = -0.38;
  rightEarGroup.rotation.y = 0.22;
  rightEarGroup.add(new THREE.Mesh(earOuterGeo, whiteFurMat));
  const rInner = new THREE.Mesh(earInnerGeo, babyPinkSkinMat);
  rInner.position.z = 0.06;
  rightEarGroup.add(rInner);
  hamsterRoot.add(rightEarGroup);

  // 7. Little Pink Front Paws Holding Keycap lower down
  const pawGeo = new THREE.SphereGeometry(0.14, 20, 20);
  pawGeo.scale(1.1, 0.75, 1.4);

  const leftPaw = new THREE.Mesh(pawGeo, babyPinkSkinMat);
  leftPaw.position.set(-0.35, 0.42, 0.98);
  leftPaw.rotation.y = 0.25;
  hamsterRoot.add(leftPaw);

  const rightPaw = new THREE.Mesh(pawGeo, babyPinkSkinMat);
  rightPaw.position.set(0.35, 0.42, 0.98);
  rightPaw.rotation.y = -0.25;
  hamsterRoot.add(rightPaw);

  // Keycap Canvas Texture with ⇪ Caps Lock
  const kCanvas = document.createElement("canvas");
  kCanvas.width = 256; kCanvas.height = 256;
  const kCtx = kCanvas.getContext("2d");
  kCtx.fillStyle = "#1E293B";
  kCtx.fillRect(0, 0, 256, 256);
  kCtx.fillStyle = "#F472B6";
  kCtx.font = "bold 90px system-ui, sans-serif";
  kCtx.textAlign = "center";
  kCtx.fillText("⇪", 128, 120);
  kCtx.font = "bold 38px system-ui, sans-serif";
  kCtx.fillText("CAPS", 128, 185);
  const kTex = new THREE.CanvasTexture(kCanvas);

  const keycapGeo = new THREE.BoxGeometry(0.52, 0.26, 0.46);
  const keycapMat = new THREE.MeshStandardMaterial({
    map: kTex,
    color: 0xFFFFFF,
    emissive: 0xFB7185,
    emissiveIntensity: 0.4,
    roughness: 0.25,
    metalness: 0.2
  });
  keycapMesh = new THREE.Mesh(keycapGeo, keycapMat);
  keycapMesh.position.set(0, 0.42, 1.05);
  keycapMesh.castShadow = true;
  hamsterRoot.add(keycapMesh);

  // Keycap Warm Glow Light
  const keycapGlow = new THREE.PointLight(0xFB7185, 1.6, 3.5);
  keycapGlow.position.set(0, 0.55, 1.25);
  hamsterRoot.add(keycapGlow);

  // 9. Soft Hind Feet Resting on Floor
  const footGeo = new THREE.SphereGeometry(0.2, 20, 20);
  footGeo.scale(1.25, 0.55, 1.8);
  const leftFoot = new THREE.Mesh(footGeo, babyPinkSkinMat);
  leftFoot.position.set(-0.72, -0.05, 0.45);
  hamsterRoot.add(leftFoot);

  const rightFoot = new THREE.Mesh(footGeo, babyPinkSkinMat);
  rightFoot.position.set(0.72, -0.05, 0.45);
  hamsterRoot.add(rightFoot);

  scene.add(hamsterRoot);
}

// --------------------------------------------------------------------------
// Flanking 3D Chrome Profile Windows (Clean, never blocking the Hamster!)
// --------------------------------------------------------------------------
function createPortalCanvas(profile) {
  const canvas = document.createElement("canvas");
  canvas.width = 640;
  canvas.height = 380;
  const ctx = canvas.getContext("2d");

  // Pure White Card Body
  ctx.fillStyle = "rgba(255, 255, 255, 0.95)";
  ctx.roundRect(0, 0, 640, 380, 28);
  ctx.fill();

  // Vibrant Border
  ctx.strokeStyle = profile.color;
  ctx.lineWidth = 6;
  ctx.roundRect(0, 0, 640, 380, 28);
  ctx.stroke();

  // Header Titlebar
  ctx.fillStyle = "rgba(0, 0, 0, 0.05)";
  ctx.fillRect(0, 0, 640, 64);

  // Traffic Lights
  ctx.fillStyle = "#FF5F56"; ctx.beginPath(); ctx.arc(36, 32, 9, 0, Math.PI*2); ctx.fill();
  ctx.fillStyle = "#FFBD2E"; ctx.beginPath(); ctx.arc(65, 32, 9, 0, Math.PI*2); ctx.fill();
  ctx.fillStyle = "#27C93F"; ctx.beginPath(); ctx.arc(94, 32, 9, 0, Math.PI*2); ctx.fill();

  // Title Text
  ctx.fillStyle = "#0F172A";
  ctx.font = "bold 24px system-ui, sans-serif";
  ctx.fillText(`Google Chrome — ${profile.name} (${profile.space})`, 130, 41);

  // Profile Icon & Heading
  ctx.font = "54px system-ui, sans-serif";
  ctx.fillText(profile.icon, 44, 150);

  ctx.fillStyle = "#0F172A";
  ctx.font = "bold 32px system-ui, sans-serif";
  ctx.fillText(`${profile.name} Profile`, 125, 134);

  ctx.fillStyle = profile.color;
  ctx.font = "bold 20px monospace";
  ctx.fillText(`⚡ 0ms SPACE TELEPORT`, 125, 168);

  // Active Tabs Preview
  ctx.fillStyle = "#475569";
  ctx.font = "22px system-ui, sans-serif";
  ctx.fillText(`Active Tabs: ${profile.tabs}`, 44, 245);

  // Omnibox URL Bar
  ctx.fillStyle = "rgba(0, 0, 0, 0.04)";
  ctx.roundRect(44, 275, 552, 54, 14);
  ctx.fill();

  ctx.fillStyle = profile.color;
  ctx.font = "20px monospace";
  ctx.fillText(`🔒 ${profile.url}`, 68, 310);

  return canvas;
}

function buildFlankingChromeWindows() {
  PROFILES.forEach((p, idx) => {
    const canvas = createPortalCanvas(p);
    const texture = new THREE.CanvasTexture(canvas);
    texture.minFilter = THREE.LinearFilter;

    const portalGeo = new THREE.PlaneGeometry(1.6, 0.95);
    const portalMat = new THREE.MeshBasicMaterial({
      map: texture,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: idx === 0 ? 1.0 : 0.0
    });

    const portalMesh = new THREE.Mesh(portalGeo, portalMat);
    // Positioned floating to the left side so the hamster is 100% visible
    portalMesh.position.set(-2.1, 0.85, 1.6);
    portalMesh.rotation.y = 0.32;
    portalMesh.userData = { profileIndex: idx };

    scene.add(portalMesh);
    profileWindows.push(portalMesh);
  });
}

// --------------------------------------------------------------------------
// Switch Profiles & Squish Physics
// --------------------------------------------------------------------------
let isSquishing = false;
let squishTime = 0;

function triggerHamsterSquish() {
  isSquishing = true;
  squishTime = 0;
  sound.playChime();
}

function switchProfile(targetIndex = null, fromUser = false) {
  if (targetIndex === null) {
    activeIndex = (activeIndex + 1) % PROFILES.length;
  } else {
    activeIndex = parseInt(targetIndex, 10);
  }

  if (fromUser) userInteracted = true;
  sound.playClick();

  // Show active window smoothly
  profileWindows.forEach((win, idx) => {
    const isTarget = idx === activeIndex;
    win.material.opacity = isTarget ? 1.0 : 0.0;
    if (isTarget) {
      win.scale.set(1.15, 1.15, 1);
      setTimeout(() => win.scale.set(1.0, 1.0, 1), 180);
    }
  });

  // Keycap Flash
  if (keycapMesh) {
    keycapMesh.material.emissiveIntensity = 2.2;
    setTimeout(() => keycapMesh.material.emissiveIntensity = 0.5, 220);
  }

  triggerHamsterSquish();
}

// --------------------------------------------------------------------------
// Mouse Handlers
// --------------------------------------------------------------------------
function onMouseMove(e) {
  mouseX = (e.clientX / window.innerWidth) * 2 - 1;
  mouseY = -(e.clientY / window.innerHeight) * 2 + 1;
  targetHeadX = mouseX * 0.28;
  targetHeadY = mouseY * 0.18;
}

function onPointerDown(e) {
  mouseVec.x = (e.clientX / window.innerWidth) * 2 - 1;
  mouseVec.y = -(e.clientY / window.innerHeight) * 2 + 1;

  raycaster.setFromCamera(mouseVec, camera);

  // Click on Giant Hamster
  const hamsterHits = raycaster.intersectObjects(hamsterRoot.children, true);
  if (hamsterHits.length > 0) {
    switchProfile(null, true);
    return;
  }

  // Click on Window
  const winHits = raycaster.intersectObjects(profileWindows);
  if (winHits.length > 0) {
    switchProfile(null, true);
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
// Animation Loop
// --------------------------------------------------------------------------
let clock = new THREE.Clock();

function animate() {
  requestAnimationFrame(animate);

  const delta = clock.getDelta();
  const time = clock.getElapsedTime();

  controls.update();

  // Giant Hamster Breathing Motion
  const breath = Math.sin(time * 2.8) * 0.02;
  if (!isSquishing && hamsterRoot) {
    hamsterRoot.scale.set(1.5 + breath * 0.2, 1.5 - breath * 0.35, 1.5 + breath * 0.2);
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

  // Whisker and nose micro-twitch
  if (snoutGroup && whiskersGroup) {
    const twitch = Math.sin(time * 22.0) * 0.012 * (Math.sin(time * 0.8) > 0.6 ? 1 : 0);
    snoutGroup.position.y = 0.95 + twitch;
    whiskersGroup.rotation.z = twitch * 1.5;
  }

  // Ear twitch
  if (leftEarGroup && rightEarGroup) {
    const earTwitch = Math.sin(time * 18.0) * 0.035 * (Math.sin(time * 0.5) > 0.8 ? 1 : 0);
    leftEarGroup.rotation.z = 0.38 + earTwitch;
    rightEarGroup.rotation.z = -0.38 - earTwitch;
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

  // Keyboard Navigation: [C], [1, 2, 3], [Space]
  window.addEventListener("keydown", (e) => {
    if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") return;

    if (e.key === "c" || e.key === "C" || e.key === " ") {
      e.preventDefault();
      switchProfile(null, true);
    } else if (e.key === "1") {
      switchProfile(0, true);
    } else if (e.key === "2") {
      switchProfile(1, true);
    } else if (e.key === "3") {
      switchProfile(2, true);
    }
  });

  // Initial intro preview after 3s
  setTimeout(() => {
    if (!userInteracted) switchProfile(1, false);
  }, 3000);
});
