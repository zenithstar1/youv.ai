/**
 * HairCapture — camera + MediaPipe Face Landmarker + animated face mask.
 *
 * Flow (inspired by premium hair-density capture UX, original YouV design):
 *   1) Fit face to upright wireframe mask → hold still
 *   2) Mask animates tilting down → user matches the tilt → hold → 3-2-1 → capture
 *
 * Flutter owns copy/UI chrome. This module owns camera, detection, mask, capture.
 */
(function (global) {
  'use strict';

  const WASM_CDN =
    'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.18/wasm';
  const MODEL_URL =
    'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task';

  const HOLD_MS = 500;
  const COUNTDOWN_TICK_MS = 450;
  const TARGET_PITCH = 45;
  const PITCH_MIN = 15;
  const PITCH_MAX = 60;
  const YAW_MAX = 18;
  const ROLL_MAX = 16;
  // Loose fit — stay roughly in the mask, not edge-to-edge fill.
  const MIN_FACE = 0.14;
  const MAX_FACE = 0.85;
  const CENTER_X_MAX = 0.32;
  const CENTER_Y_MAX = 0.38;
  const BRIGHT_MIN = 48;
  const BRIGHT_MAX = 220;
  const BLUR_MIN = 18;
  const MOTION_MAX = 0.036;
  const MASK_TILT_MAX = 0.72; // radians (~41°)
  const MASK_TILT_SPEED = 0.045;

  let faceLandmarker = null;
  let loadPromise = null;
  let stream = null;
  let video = null;
  let host = null;
  let maskCanvas = null;
  let maskCtx = null;
  let workCanvas = null;
  let workCtx = null;
  let rafId = 0;
  let running = false;
  let lastVideoTime = -1;

  /** @type {'face'|'face_hold'|'tilt'|'tilt_hold'|'countdown'|'capture'} */
  let phase = 'face';
  let holdStart = 0;
  let countdownStart = 0;
  let captured = false;
  let lastCenter = null;
  let lastEmit = 0;
  let maskAngle = 0; // current animated tilt
  let maskPulse = 0;

  let onUpdate = null;
  let onCaptured = null;
  let onError = null;

  function emit(state) {
    const now = performance.now();
    if (now - lastEmit < 40 && state.phase !== 'capture') return;
    lastEmit = now;
    try {
      if (typeof onUpdate === 'function') onUpdate(state);
    } catch (_) { }
    try {
      global.dispatchEvent(
        new CustomEvent('hairCaptureUpdate', { detail: state }),
      );
    } catch (_) { }
  }

  function fail(message) {
    try {
      if (typeof onError === 'function') onError(message);
    } catch (_) { }
    try {
      global.dispatchEvent(
        new CustomEvent('hairCaptureError', { detail: message }),
      );
    } catch (_) { }
  }

  async function ensureLandmarker() {
    if (faceLandmarker) return faceLandmarker;
    if (loadPromise) return loadPromise;

    loadPromise = (async () => {
      const vision = await import(
        'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.18/+esm'
      );
      const fileset = await vision.FilesetResolver.forVisionTasks(WASM_CDN);
      const opts = {
        baseOptions: { modelAssetPath: MODEL_URL, delegate: 'GPU' },
        runningMode: 'VIDEO',
        numFaces: 1,
        outputFaceBlendshapes: false,
        outputFacialTransformationMatrixes: true,
      };
      try {
        faceLandmarker = await vision.FaceLandmarker.createFromOptions(
          fileset,
          opts,
        );
      } catch (_) {
        opts.baseOptions.delegate = 'CPU';
        faceLandmarker = await vision.FaceLandmarker.createFromOptions(
          fileset,
          opts,
        );
      }
      return faceLandmarker;
    })().catch((err) => {
      loadPromise = null;
      throw err;
    });

    return loadPromise;
  }

  function resolveHost(container) {
    if (!container) return null;
    if (typeof container === 'string') {
      return document.getElementById(container);
    }
    return container;
  }

  function buildUi(parent) {
    parent.innerHTML = '';
    parent.style.position = 'relative';
    parent.style.overflow = 'hidden';
    parent.style.background = '#1a1212';

    video = document.createElement('video');
    video.setAttribute('playsinline', '');
    video.setAttribute('autoplay', '');
    video.muted = true;
    video.playsInline = true;
    Object.assign(video.style, {
      position: 'absolute',
      inset: '0',
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      transform: 'scale(-1.25, 1.25)', // Zoom in 1.25x and flip horizontally
    });
    parent.appendChild(video);

    maskCanvas = document.createElement('canvas');
    Object.assign(maskCanvas.style, {
      position: 'absolute',
      inset: '0',
      width: '100%',
      height: '100%',
      pointerEvents: 'none',
    });
    parent.appendChild(maskCanvas);
    maskCtx = maskCanvas.getContext('2d');

    workCanvas = document.createElement('canvas');
    workCtx = workCanvas.getContext('2d', { willReadFrequently: true });
  }

  function resizeMaskCanvas() {
    if (!maskCanvas || !host) return;
    const w = host.clientWidth || 360;
    const h = host.clientHeight || 480;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    if (maskCanvas.width !== Math.round(w * dpr) || maskCanvas.height !== Math.round(h * dpr)) {
      maskCanvas.width = Math.round(w * dpr);
      maskCanvas.height = Math.round(h * dpr);
      maskCtx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
  }

  /**
   * Tilting wireframe mask + large text overlay.
   */
  function drawMask(checks, now) {
    if (!maskCtx || !host) return;
    resizeMaskCanvas();
    const w = host.clientWidth || 360;
    const h = host.clientHeight || 480;
    const ctx = maskCtx;
    ctx.clearRect(0, 0, w, h);

    const matched =
      phase === 'face' || phase === 'face_hold'
        ? checks.face && checks.centered && checks.lighting
        : checks.pose;

    maskPulse = 0.6 + 0.4 * Math.sin(now / 480);

    const targetTilt =
      phase === 'face' || phase === 'face_hold' ? 0 : MASK_TILT_MAX;
    if (maskAngle < targetTilt) {
      maskAngle = Math.min(targetTilt, maskAngle + MASK_TILT_SPEED);
    } else if (maskAngle > targetTilt) {
      maskAngle = Math.max(targetTilt, maskAngle - MASK_TILT_SPEED);
    }

    const cx = w * 0.5;
    const cy = h * 0.42;
    const s = Math.min(w, h) * 0.38;

    const alpha = matched ? 0.88 : 0.5 + maskPulse * 0.35;
    const color = matched
      ? 'rgba(150, 205, 175,' + alpha + ')'
      : 'rgba(255, 250, 246,' + alpha + ')';

    ctx.save();
    // Move the mask slightly down to simulate nodding forward
    ctx.translate(cx, cy + maskAngle * s * 0.35);
    // Squish the mask vertically to simulate 3D pitch perspective
    ctx.scale(1, 1 - maskAngle * 0.15);

    ctx.strokeStyle = color;
    ctx.lineWidth = matched ? 2.4 : 1.5; // Thinner for a more subtle look
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    // Minimalist Oval Face Outline with Wireframe cross-sections
    ctx.beginPath();
    ctx.ellipse(0, 0, s * 0.68, s * 0.95, 0, 0, 2 * Math.PI);

    // Vertical center line
    ctx.moveTo(0, -s * 0.95);
    ctx.lineTo(0, s * 0.95);

    // Horizontal eye line
    ctx.moveTo(-s * 0.64, -s * 0.1);
    ctx.quadraticCurveTo(0, s * 0.1, s * 0.64, -s * 0.1);

    // Horizontal nose line
    ctx.moveTo(-s * 0.54, s * 0.3);
    ctx.quadraticCurveTo(0, s * 0.45, s * 0.54, s * 0.3);

    // Horizontal chin/mouth line
    ctx.moveTo(-s * 0.4, s * 0.65);
    ctx.quadraticCurveTo(0, s * 0.75, s * 0.4, s * 0.65);

    ctx.stroke();

    // Clean pink downward arrow on the head during tilt phase
    if (phase === 'tilt' && !checks.pose) {
      drawTiltArrow(ctx, 0, -s * 0.95 - 20, now);
    }

    ctx.restore();

    // Draw large text overlay centered on the face
    let caption = '';
    if (phase === 'face' || phase === 'face_hold') {
      caption = 'Look Straight';
    } else if (phase === 'tilt' || phase === 'tilt_hold') {
      caption = 'Tilt head down 45°';
    } else if (phase === 'countdown') {
      caption = 'Hold Still...';
    }

    if (caption) {
      ctx.save();
      ctx.resetTransform();
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      ctx.scale(dpr, dpr);
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.font = '600 34px "Inter", "Roboto", "Helvetica Neue", sans-serif';
      ctx.fillStyle = 'rgba(255, 255, 255, 1)';
      ctx.shadowColor = 'rgba(0, 0, 0, 0.75)';
      ctx.shadowBlur = 16;
      ctx.shadowOffsetX = 0;
      ctx.shadowOffsetY = 2;
      ctx.fillText(caption, w * 0.5, h * 0.45);
      ctx.restore();
    }
  }

  function drawTiltArrow(ctx, cx, cy, now) {
    const bob = Math.sin(now / 380) * 8;
    const ay = cy + bob;

    ctx.save();
    ctx.strokeStyle = 'rgba(240, 20, 90, 0.9)'; // Vivid pink
    ctx.fillStyle = 'rgba(240, 20, 90, 0.9)';
    ctx.lineWidth = 4;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    // Simple, clean downward arrow
    ctx.beginPath();
    ctx.moveTo(cx, ay - 24);
    ctx.lineTo(cx, ay + 6);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(cx - 10, ay - 4);
    ctx.lineTo(cx, ay + 12);
    ctx.lineTo(cx + 10, ay - 4);
    ctx.fill();
    ctx.stroke();

    ctx.restore();
  }

  function matrixArray(matrix) {
    if (!matrix) return null;
    if (matrix.data) return matrix.data;
    if (
      Array.isArray(matrix) ||
      (typeof matrix.length === 'number' && matrix.length >= 16)
    ) {
      return matrix;
    }
    return null;
  }

  function poseFromMatrix(matrixData) {
    const m = matrixArray(matrixData);
    if (!m || m.length < 16) return null;

    const r01 = m[4];
    const r11 = m[5];
    const r20 = m[2];
    const r21 = m[6];
    const r22 = m[10];

    const pitch = (Math.asin(Math.max(-1, Math.min(1, -r21))) * 180) / Math.PI;
    const yaw = (Math.atan2(r20, r22) * 180) / Math.PI;
    const roll = (Math.atan2(r01, r11) * 180) / Math.PI;

    return {
      pitch: Math.abs(pitch),
      yaw: Math.abs(yaw),
      roll: Math.abs(roll),
      rawPitch: pitch,
      rawYaw: yaw,
      rawRoll: roll,
    };
  }

  function poseFromLandmarks(landmarks) {
    if (!landmarks || landmarks.length < 153) return null;
    const forehead = landmarks[10];
    const nose = landmarks[1];
    const chin = landmarks[152];
    const leftCheek = landmarks[234];
    const rightCheek = landmarks[454];

    const dForeheadNose = Math.abs(nose.y - forehead.y);
    const dNoseChin = Math.abs(chin.y - nose.y) || 1e-6;
    const pitch = (Math.atan(dForeheadNose / dNoseChin) * 180) / Math.PI;

    const midX = (leftCheek.x + rightCheek.x) / 2;
    const yaw =
      ((nose.x - midX) / Math.abs(rightCheek.x - leftCheek.x || 1e-6)) * 40;

    const eyeL = landmarks[33];
    const eyeR = landmarks[263];
    const roll =
      (Math.atan2(eyeR.y - eyeL.y, eyeR.x - eyeL.x) * 180) / Math.PI;

    return {
      pitch: Math.abs(pitch),
      yaw: Math.abs(yaw),
      roll: Math.abs(roll),
      rawPitch: pitch,
      rawYaw: yaw,
      rawRoll: roll,
    };
  }

  function faceMetrics(landmarks) {
    let minX = 1;
    let maxX = 0;
    let minY = 1;
    let maxY = 0;
    for (let i = 0; i < landmarks.length; i++) {
      const p = landmarks[i];
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    const cx = 1 - (minX + maxX) / 2;
    const cy = (minY + maxY) / 2;
    return {
      faceWidth: maxX - minX,
      faceHeight: maxY - minY,
      centerX: cx,
      centerY: cy,
      offsetX: Math.abs(cx - 0.5),
      offsetY: Math.abs(cy - 0.44),
    };
  }

  function sampleBrightnessAndBlur() {
    if (!video || !workCtx || video.videoWidth < 16) {
      return { brightness: 128, blurScore: 100 };
    }
    const sw = 96;
    const sh = Math.max(
      54,
      Math.round((video.videoHeight / video.videoWidth) * sw),
    );
    workCanvas.width = sw;
    workCanvas.height = sh;
    workCtx.drawImage(video, 0, 0, sw, sh);
    const data = workCtx.getImageData(0, 0, sw, sh).data;

    let sum = 0;
    const gray = new Float32Array(sw * sh);
    for (let i = 0, p = 0; i < data.length; i += 4, p++) {
      const g = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
      gray[p] = g;
      sum += g;
    }
    const brightness = sum / gray.length;

    let lapSum = 0;
    let lapSq = 0;
    let n = 0;
    for (let y = 1; y < sh - 1; y++) {
      for (let x = 1; x < sw - 1; x++) {
        const i = y * sw + x;
        const v =
          -4 * gray[i] +
          gray[i - 1] +
          gray[i + 1] +
          gray[i - sw] +
          gray[i + sw];
        lapSum += v;
        lapSq += v * v;
        n++;
      }
    }
    const mean = lapSum / (n || 1);
    const blurScore = lapSq / (n || 1) - mean * mean;
    return { brightness, blurScore };
  }

  function stepNumber(p) {
    if (p === 'face' || p === 'face_hold') return 1;
    return 2;
  }

  function titleFor(p) {
    if (p === 'capture' || p === 'countdown') {
      return 'Capturing';
    }
    if (p === 'tilt' || p === 'tilt_hold') {
      return 'Step 2: Lower Head';
    }
    return 'Step 1: Look Straight';
  }

  function instructionFor(checks, p, countdown) {
    if (p === 'capture') return 'Stay perfectly still...';
    if (p === 'countdown') return 'Photo will be taken...';
    if (p === 'tilt_hold') return 'Hold still...';
    if (p === 'tilt') {
      if (!checks.pose) return 'Tilt head down 45°.';
      return 'Hold still...';
    }
    if (p === 'face_hold') return 'Hold still...';
    if (!checks.face) return 'Look straight into the camera.';
    if (!checks.lighting) return 'Ensure proper lighting.';
    if (!checks.size || !checks.centered) {
      return 'Center your face in the outline.';
    }
    if (!checks.sharp) return 'Hold steady — image looks soft.';
    return 'Hold still...';
  }

  function linesFor(checks, p, countdown) {
    const lines = [];
    if (p === 'face' || p === 'face_hold') {
      if (checks.face) lines.push('✓ Face detected');
      if (checks.lighting) lines.push('✓ Good lighting');
      if (checks.face && checks.lighting && checks.centered && checks.size) {
        lines.push('✓ Hold still...');
      }
    } else if (p === 'tilt' || p === 'tilt_hold') {
      if (checks.pose || p === 'tilt_hold') {
        lines.push('✓ Correct position');
      }
      if (p === 'tilt_hold') {
        lines.push('⏳ Stabilizing...');
      }
    } else if (p === 'countdown') {
      lines.push('✓ Correct position');
      if (countdown != null) lines.push(String(countdown) + '...');
    } else if (p === 'capture') {
      lines.push('📸 Capturing...');
    }
    return lines;
  }

  async function captureFrame() {
    if (!video) throw new Error('No video');
    const w = video.videoWidth || 720;
    const h = video.videoHeight || 960;

    // Calculate the crop to match the 1.25x CSS zoom
    const zoom = 1.25;
    const cropW = w / zoom;
    const cropH = h / zoom;
    const cropX = (w - cropW) / 2;
    const cropY = (h - cropH) / 2;

    const canvas = document.createElement('canvas');
    canvas.width = cropW;
    canvas.height = cropH;
    const ctx = canvas.getContext('2d');

    // Flip horizontally to match mirror preview
    ctx.translate(cropW, 0);
    ctx.scale(-1, 1);

    // Draw the cropped center portion
    ctx.drawImage(video, cropX, cropY, cropW, cropH, 0, 0, cropW, cropH);

    const dataUrl = canvas.toDataURL('image/jpeg', 0.92);
    const imageBase64 = dataUrl.split(',')[1] || '';
    return { imageBase64, mimeType: 'image/jpeg', dataUrl };
  }

  function round1(n) {
    return Math.round((n || 0) * 10) / 10;
  }

  function pushState(checks, pose, iq, progress, countdown) {
    emit({
      step: stepNumber(phase),
      phase,
      title: titleFor(phase),
      instruction: instructionFor(checks, phase, countdown),
      status: instructionFor(checks, phase, countdown),
      lines: linesFor(checks, phase, countdown),
      progress,
      countdown,
      maskTilt: Math.round((maskAngle / MASK_TILT_MAX) * 100) / 100,
      pose: {
        pitch: round1(pose.pitch),
        yaw: round1(pose.yaw),
        roll: round1(pose.roll),
        targetPitch: TARGET_PITCH,
      },
      checks,
      brightness: Math.round(iq.brightness),
      blurScore: Math.round(iq.blurScore),
    });
  }

  function loop() {
    if (!running) return;
    rafId = requestAnimationFrame(loop);

    const now = performance.now();
    const emptyChecks = {
      face: false,
      lighting: false,
      sharp: false,
      still: false,
      size: false,
      centered: false,
      pose: false,
    };

    if (!video || !faceLandmarker || video.readyState < 2) {
      drawMask(emptyChecks, now);
      return;
    }
    if (captured) return;

    const isNewFrame = video.currentTime !== lastVideoTime;
    if (!isNewFrame) {
      drawMask(loop._lastChecks || emptyChecks, now);
      return;
    }
    lastVideoTime = video.currentTime;

    let result;
    try {
      result = faceLandmarker.detectForVideo(video, now);
    } catch (_) {
      drawMask(loop._lastChecks || emptyChecks, now);
      return;
    }

    const hasFace =
      !!(result && result.faceLandmarks && result.faceLandmarks.length > 0);

    const iq = sampleBrightnessAndBlur();
    const lighting =
      iq.brightness >= BRIGHT_MIN && iq.brightness <= BRIGHT_MAX;
    const sharp = iq.blurScore >= BLUR_MIN;

    let pose = { pitch: 0, yaw: 0, roll: 0 };
    let still = false;
    let sizeOk = false;
    let centered = false;
    let poseOk = false;

    if (hasFace) {
      const lm = result.faceLandmarks[0];
      const metrics = faceMetrics(lm);
      const matrix =
        result.facialTransformationMatrixes &&
        result.facialTransformationMatrixes[0];
      pose = poseFromMatrix(matrix) || poseFromLandmarks(lm) || pose;

      sizeOk =
        metrics.faceWidth >= MIN_FACE && metrics.faceWidth <= MAX_FACE;
      centered =
        metrics.offsetX <= CENTER_X_MAX && metrics.offsetY <= CENTER_Y_MAX;

      if (lastCenter) {
        const dx = Math.abs(metrics.centerX - lastCenter.x);
        const dy = Math.abs(metrics.centerY - lastCenter.y);
        still = dx < MOTION_MAX && dy < MOTION_MAX;
      } else {
        still = true;
      }
      lastCenter = { x: metrics.centerX, y: metrics.centerY };

      poseOk =
        pose.pitch >= PITCH_MIN &&
        pose.pitch <= PITCH_MAX &&
        pose.yaw <= YAW_MAX &&
        pose.roll <= ROLL_MAX;
    } else {
      lastCenter = null;
      still = false;
    }

    const checks = {
      face: !!hasFace,
      lighting: !!hasFace && lighting,
      sharp: !!hasFace && sharp,
      still: !!hasFace && still,
      size: !!hasFace && sizeOk,
      centered: !!hasFace && centered,
      pose: !!hasFace && poseOk,
    };
    loop._lastChecks = checks;

    const faceReady =
      checks.face &&
      checks.lighting &&
      checks.sharp &&
      checks.still &&
      checks.size &&
      checks.centered;

    const tiltBasics =
      checks.face && checks.lighting && checks.sharp && checks.still;
    const tiltReady = tiltBasics && checks.pose;

    let progress = 0;
    let countdown = null;

    if (phase === 'face') {
      if (faceReady) {
        phase = 'face_hold';
        holdStart = now;
      }
    } else if (phase === 'face_hold') {
      if (!faceReady) {
        phase = 'face';
        holdStart = 0;
      } else {
        progress = Math.min(1, (now - holdStart) / HOLD_MS);
        if (now - holdStart >= HOLD_MS) {
          phase = 'tilt';
          holdStart = 0;
          progress = 0;
        }
      }
    } else if (phase === 'tilt') {
      if (tiltReady) {
        phase = 'tilt_hold';
        holdStart = now;
      }
    } else if (phase === 'tilt_hold') {
      if (!tiltReady) {
        phase = 'tilt';
        holdStart = 0;
      } else {
        progress = Math.min(1, (now - holdStart) / HOLD_MS);
        if (now - holdStart >= HOLD_MS) {
          phase = 'countdown';
          countdownStart = now;
          progress = 1;
        }
      }
    } else if (phase === 'countdown') {
      // Once the countdown starts on mobile, commit to it fully. 
      // Do not abort if face flickers, as mobile frame drops easily cause frustrating resets.
      progress = 1;
      const elapsed = now - countdownStart;
      if (elapsed < COUNTDOWN_TICK_MS) countdown = 3;
      else if (elapsed < COUNTDOWN_TICK_MS * 2) countdown = 2;
      else if (elapsed < COUNTDOWN_TICK_MS * 3) countdown = 1;
      else {
        phase = 'capture';
        countdown = null;
        drawMask(checks, now);
        void finishCapture(pose, checks, iq);
        return;
      }
    }

    drawMask(checks, now);
    pushState(checks, pose, iq, progress, countdown);
  }
  loop._lastChecks = null;

  async function finishCapture(pose, checks, iq) {
    if (captured) return;
    captured = true;
    phase = 'capture';
    pushState(checks, pose, iq || { brightness: 0, blurScore: 0 }, 1, null);

    try {
      const shot = await captureFrame();
      const payload = {
        imageBase64: shot.imageBase64,
        mimeType: shot.mimeType,
        pose: {
          pitch: round1(pose.pitch),
          yaw: round1(pose.yaw),
          roll: round1(pose.roll),
        },
      };
      try {
        if (typeof onCaptured === 'function') onCaptured(payload);
      } catch (_) { }
      try {
        global.dispatchEvent(
          new CustomEvent('hairCaptureCaptured', { detail: payload }),
        );
      } catch (_) { }
    } catch (err) {
      captured = false;
      phase = 'tilt';
      fail(err && err.message ? err.message : 'Capture failed');
    }
  }

  async function start(options) {
    await stop();
    options = options || {};
    onUpdate = options.onUpdate || null;
    onCaptured = options.onCaptured || null;
    onError = options.onError || null;
    captured = false;
    phase = 'face';
    holdStart = 0;
    countdownStart = 0;
    lastCenter = null;
    lastVideoTime = -1;
    lastEmit = 0;
    maskAngle = 0;
    loop._lastChecks = null;

    host = resolveHost(options.container || options.containerId);
    if (!host) {
      fail('Camera container not found');
      return false;
    }

    try {
      await ensureLandmarker();
    } catch (err) {
      fail(
        'Could not load face analysis. Check your connection and try again.',
      );
      console.error('[HairCapture] landmarker load failed', err);
      return false;
    }

    buildUi(host);

    try {
      stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          facingMode: { ideal: 'user' },
          frameRate: { ideal: 30, max: 30 },
        },
      });
    } catch (err) {
      fail('Camera permission is required for Quick Scan.');
      return false;
    }

    video.srcObject = stream;
    try {
      await video.play();
    } catch (_) { }

    running = true;
    rafId = requestAnimationFrame(loop);
    pushState(
      {
        face: false,
        lighting: false,
        sharp: false,
        still: false,
        size: false,
        centered: false,
        pose: false,
      },
      { pitch: 0, yaw: 0, roll: 0 },
      { brightness: 0, blurScore: 0 },
      0,
      null,
    );
    return true;
  }

  async function stop() {
    running = false;
    if (rafId) {
      cancelAnimationFrame(rafId);
      rafId = 0;
    }
    if (stream) {
      stream.getTracks().forEach((t) => t.stop());
      stream = null;
    }
    if (video) {
      try {
        video.srcObject = null;
      } catch (_) { }
      video = null;
    }
    if (host) {
      host.innerHTML = '';
      host = null;
    }
    maskCanvas = null;
    maskCtx = null;
    workCanvas = null;
    workCtx = null;
    onUpdate = null;
    onCaptured = null;
    onError = null;
    captured = false;
    phase = 'face';
    maskAngle = 0;
  }

  global.HairCapture = {
    start,
    stop,
    isRunning: () => running,
    version: '1.3.1',
  };
})(typeof window !== 'undefined' ? window : globalThis);
