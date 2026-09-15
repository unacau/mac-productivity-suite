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

  // Ambient Light: Bright, Radiant, Balanced (Zero Washout)
  const ambient = new THREE.AmbientLight(0xFFF0F5, 1.05);
  scene.add(ambient);

  // Studio Key Light
  const keyLight = new THREE.DirectionalLight(0xFFFFFF, 1.35);
  keyLight.position.set(4, 8, 6);
  keyLight.castShadow = true;
  keyLight.shadow.mapSize.width = 2048;
  keyLight.shadow.mapSize.height = 2048;
  keyLight.shadow.bias = -0.0004;
  scene.add(keyLight);

  // Soft Rosy-Pink Rim Light
  const rimLight = new THREE.DirectionalLight(0xF472B6, 1.25);
  rimLight.position.set(-5, 4.5, -5);
  scene.add(rimLight);

  // Front Soft Fill
  const fillLight = new THREE.PointLight(0xFCE7F3, 0.8, 12);
  fillLight.position.set(0, 1.2, 3.5);
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
  const leftPawGroup = new THREE.Group();
  leftPawGroup.position.set(-0.44, 0.44, 0.94);
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
  rightPawGroup.position.set(0.44, 0.44, 0.94);
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

  // 6. Blue "Caps Lock" Keycap with Glowing Green LED & Yellow Arrow
  const kCanvas = document.createElement("canvas");
  kCanvas.width = 512; kCanvas.height = 360;
  const kCtx = kCanvas.getContext("2d");

  // Deep Navy Royal Blue Gradient
  const grad = kCtx.createLinearGradient(0, 0, 0, 360);
  grad.addColorStop(0, "#0F2B66");
  grad.addColorStop(1, "#081636");
  kCtx.fillStyle = grad;
  kCtx.fillRect(0, 0, 512, 360);

  // Soft inner border for keycap chamfer
  kCtx.strokeStyle = "rgba(255, 255, 255, 0.22)";
  kCtx.lineWidth = 6;
  kCtx.strokeRect(12, 12, 488, 336);

  // Glowing Green LED Dot with Soft Radial Glow Halo
  const ledGlow = kCtx.createRadialGradient(80, 85, 4, 80, 85, 48);
  ledGlow.addColorStop(0, "#86EFAC");
  ledGlow.addColorStop(0.3, "rgba(34, 197, 94, 0.85)");
  ledGlow.addColorStop(1, "rgba(34, 197, 94, 0)");
  kCtx.fillStyle = ledGlow;
  kCtx.beginPath();
  kCtx.arc(80, 85, 48, 0, Math.PI * 2);
  kCtx.fill();

  kCtx.fillStyle = "#22C55E";
  kCtx.beginPath();
  kCtx.arc(80, 85, 14, 0, Math.PI * 2);
  kCtx.fill();

  // Bold Golden-Yellow Upward Arrow (Caps Lock Symbol) with crisp dark outline
  kCtx.save();
  kCtx.translate(256, 145);
  kCtx.beginPath();
  kCtx.moveTo(0, -70);      // top tip
  kCtx.lineTo(58, -14);     // right corner
  kCtx.lineTo(26, -14);     // right notch
  kCtx.lineTo(26, 50);      // right stem bottom
  kCtx.lineTo(-26, 50);     // left stem bottom
  kCtx.lineTo(-26, -14);    // left notch
  kCtx.lineTo(-58, -14);    // left corner
  kCtx.closePath();
  kCtx.fillStyle = "#FFD700";
  kCtx.fill();
  kCtx.strokeStyle = "#0F172A";
  kCtx.lineWidth = 7;
  kCtx.lineJoin = "round";
  kCtx.stroke();
  kCtx.restore();

  // Crisp White "caps lock" Text
  kCtx.fillStyle = "#FFFFFF";
  kCtx.font = "bold 44px -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
  kCtx.textAlign = "center";
  kCtx.fillText("caps lock", 256, 280);

  const kTex = new THREE.CanvasTexture(kCanvas);
  kTex.anisotropy = 4;

  const keycapGeo = new THREE.BoxGeometry(1.48, 0.72, 0.40);
  const keycapBodyMat = new THREE.MeshBasicMaterial({
    color: 0x0A1C42
  });
  const keycapFrontMat = new THREE.MeshBasicMaterial({
    map: kTex
  });

  // Six-sided material mapping so texture ONLY appears on front (+Z face, index 4)
  keycapMesh = new THREE.Mesh(keycapGeo, [
    keycapBodyMat, keycapBodyMat, keycapBodyMat, keycapBodyMat, keycapFrontMat, keycapBodyMat
  ]);
  keycapMesh.position.set(0, 0.12, 0.88);
  keycapMesh.castShadow = true;
  hamsterRoot.add(keycapMesh);

  // Real 3D Glowing Green LED PointLight
  const greenLedLight = new THREE.PointLight(0x22C55E, 3.2, 2.5);
  greenLedLight.position.set(-0.52, 0.28, 1.15);
  hamsterRoot.add(greenLedLight);

  // 7. Soft Hind Feet Resting on Marble Floor
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
