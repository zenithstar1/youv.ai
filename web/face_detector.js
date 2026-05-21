console.log("face_detector.js loaded");

// ── Page-load diagnostics ─────────────────────────────────────────────────────
(function logPageState() {
  console.log('[PageDiag]', {
    ua:        navigator.userAgent,
    screenWH:  screen.width + '×' + screen.height,
    innerWH:   window.innerWidth + '×' + window.innerHeight,
    dpr:       window.devicePixelRatio,
    isMobile:  /iPhone|iPad|iPod|Android/i.test(navigator.userAgent),
    isIOS:     /iPhone|iPad|iPod/i.test(navigator.userAgent),
  });
})();

let faceMesh = null;
let cameraStarted = false;
let animFrameId = null;
let targetVideo = null;

const DETECTION_WINDOW_SIZE = 10;
const ACQUIRE_CONSECUTIVE_FRAMES = 3;
const ACQUIRE_VALID_IN_WINDOW = 4;
const RELEASE_VALID_IN_WINDOW = 1;
const RELEASE_MISSED_FRAMES = 1;
let consecutiveFaceFrames = 0;
let missedFaceFrames = 0;
let processing = false;
let lastDetectedState = false;
let recentFaceValidity = [];
let lastProcessAt = 0;
let stillImageFaceMesh = null;
let browserFaceDetector = null;

const PROCESS_INTERVAL_MS = 80;

function dispatchFaceDetected(detected) {
  if (detected !== lastDetectedState) {
    const validInWindow = recentFaceValidity.reduce((sum, val) => sum + (val ? 1 : 0), 0);
    console.log(`[FaceDetection] state -> ${detected ? "DETECTED" : "NOT_DETECTED"}, consecutive=${consecutiveFaceFrames}, missed=${missedFaceFrames}, window=${validInWindow}/${recentFaceValidity.length}`);
    lastDetectedState = detected;
  }

  window.dispatchEvent(
    new CustomEvent("faceDetected", { detail: detected })
  );
}

function getVideoScore(video) {
  if (!video || video.tagName !== "VIDEO") return -1;
  if (!video.isConnected) return -1;

  const width = video.videoWidth || 0;
  const height = video.videoHeight || 0;
  if (width === 0 || height === 0) return -1;
  if (video.readyState < 2) return -1;

  const rect = video.getBoundingClientRect();
  const rectArea = Math.max(0, rect.width) * Math.max(0, rect.height);
  const streamArea = width * height;
  const visibleBoost = rectArea > 0 ? 1000000 : 0;

  return visibleBoost + rectArea + streamArea;
}

function findBestVideoElement(preferredVideo) {
  let best = null;
  let bestScore = -1;

  if (preferredVideo) {
    const score = getVideoScore(preferredVideo);
    if (score > bestScore) {
      best = preferredVideo;
      bestScore = score;
    }
  }

  const videos = document.querySelectorAll("video");
  for (let i = 0; i < videos.length; i++) {
    const video = videos[i];
    const score = getVideoScore(video);
    if (score > bestScore) {
      best = video;
      bestScore = score;
    }
  }

  return best;
}

function createFaceMeshInstance() {
  const mesh = new FaceMesh({
    locateFile: (file) =>
      `https://cdn.jsdelivr.net/npm/@mediapipe/face_mesh/${file}`
  });

  mesh.setOptions({
    maxNumFaces: 1,
    refineLandmarks: true,
    minDetectionConfidence: 0.70,
    minTrackingConfidence: 0.70
  });

  return mesh;
}

function getBrowserFaceDetector() {
  if (!('FaceDetector' in window)) {
    return null;
  }

  if (!browserFaceDetector) {
    browserFaceDetector = new window.FaceDetector({
      fastMode: false,
      maxDetectedFaces: 1,
    });
  }

  return browserFaceDetector;
}

function loadImageFromDataUrl(dataUrl) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = reject;
    image.src = dataUrl;
  });
}

function createCroppedImage(image, cropRatio) {
  const sourceWidth = image.naturalWidth || image.width;
  const sourceHeight = image.naturalHeight || image.height;
  const cropWidth = Math.max(1, Math.floor(sourceWidth * cropRatio));
  const cropHeight = Math.max(1, Math.floor(sourceHeight * cropRatio));
  const offsetX = Math.max(0, Math.floor((sourceWidth - cropWidth) / 2));
  const offsetY = Math.max(0, Math.floor((sourceHeight - cropHeight) / 2));

  const canvas = document.createElement('canvas');
  canvas.width = cropWidth;
  canvas.height = cropHeight;

  const context = canvas.getContext('2d');
  if (!context) return null;

  context.drawImage(
    image,
    offsetX,
    offsetY,
    cropWidth,
    cropHeight,
    0,
    0,
    cropWidth,
    cropHeight
  );

  return canvas;
}

async function validateStillFrame(frameImage) {
  if (!stillImageFaceMesh) {
    stillImageFaceMesh = createFaceMeshInstance();
  }

  const browserValidation = await validateBrowserDetectedFace(frameImage);
  if (browserValidation === false) {
    return false;
  }

  return await new Promise(async (resolve) => {
    let resolved = false;
    stillImageFaceMesh.onResults((results) => {
      if (resolved) return;
      resolved = true;
      const valid = !!(
        results.multiFaceLandmarks &&
        results.multiFaceLandmarks.length > 0 &&
        isValidCapturedFace(results.multiFaceLandmarks[0])
      );
      resolve(valid);
    });

    try {
      await stillImageFaceMesh.send({ image: frameImage });
      if (!resolved) {
        resolved = true;
        resolve(false);
      }
    } catch (e) {
      console.warn('Still image face validation failed:', e);
      if (!resolved) {
        resolved = true;
        resolve(false);
      }
    }
  });
}

function getFaceLandmark(face, expectedType) {
  if (!face || !Array.isArray(face.landmarks)) return null;

  for (const landmark of face.landmarks) {
    if (!landmark || typeof landmark.type !== 'string') continue;
    if (landmark.type.toLowerCase() === expectedType) {
      return landmark.location || landmark;
    }
  }

  return null;
}

function validateBrowserFaceGeometry(face, imageWidth, imageHeight) {
  const box = face.boundingBox;
  if (!box || imageWidth <= 0 || imageHeight <= 0) {
    return false;
  }

  const faceWidthRatio = box.width / imageWidth;
  const faceHeightRatio = box.height / imageHeight;
  const faceAreaRatio = (box.width * box.height) / (imageWidth * imageHeight);
  const aspectRatio = box.width / Math.max(box.height, 1);
  const centerX = box.x + (box.width / 2);
  const centerY = box.y + (box.height / 2);
  const offsetX = Math.abs(centerX - (imageWidth / 2)) / (imageWidth / 2);
  const offsetY = Math.abs(centerY - (imageHeight / 2)) / (imageHeight / 2);

  if (faceWidthRatio < 0.16 || faceWidthRatio > 0.74) return false;
  if (faceHeightRatio < 0.22 || faceHeightRatio > 0.84) return false;
  if (faceAreaRatio < 0.055 || faceAreaRatio > 0.54) return false;
  if (aspectRatio < 0.52 || aspectRatio > 1.28) return false;
  if (offsetX > 0.28 || offsetY > 0.32) return false;

  const leftEye = getFaceLandmark(face, 'eye');
  const rightEye = Array.isArray(face.landmarks)
    ? face.landmarks
        .filter((landmark) => landmark && typeof landmark.type === 'string' && landmark.type.toLowerCase() === 'eye')
        .map((landmark) => landmark.location || landmark)
    : [];
  const nose = getFaceLandmark(face, 'nose');
  const mouth = getFaceLandmark(face, 'mouth');

  if (!leftEye || rightEye.length < 2 || !nose || !mouth) {
    return false;
  }

  const eyeA = rightEye[0];
  const eyeB = rightEye[1];
  const eyeDx = Math.abs(eyeA.x - eyeB.x);
  const eyeDy = Math.abs(eyeA.y - eyeB.y);
  if (eyeDx <= 0) return false;

  const eyesLevel = eyeDy / eyeDx;
  const eyeMidX = (eyeA.x + eyeB.x) / 2;
  const eyeMidY = (eyeA.y + eyeB.y) / 2;
  const eyeBandMinY = imageHeight * 0.31;
  const eyeBandMaxY = imageHeight * 0.44;
  const noseCenteredToEyes = Math.abs(nose.x - eyeMidX) / eyeDx;
  const mouthWidthToEyes = Math.abs(mouth.x - eyeMidX) / eyeDx;

  if (eyesLevel > 0.10) return false;
  if (eyeMidY < eyeBandMinY || eyeMidY > eyeBandMaxY) return false;
  if (nose.y <= eyeMidY) return false;
  if (noseCenteredToEyes > 0.60) return false;
  if (mouth.y <= nose.y) return false;
  if (mouthWidthToEyes > 0.75) return false;

  return true;
}

async function validateBrowserDetectedFace(frameImage) {
  const detector = getBrowserFaceDetector();
  if (!detector) {
    return null;
  }

  try {
    const faces = await detector.detect(frameImage);
    if (!Array.isArray(faces) || faces.length !== 1) {
      return false;
    }

    const imageWidth = frameImage.naturalWidth || frameImage.videoWidth || frameImage.width || 0;
    const imageHeight = frameImage.naturalHeight || frameImage.videoHeight || frameImage.height || 0;
    return validateBrowserFaceGeometry(faces[0], imageWidth, imageHeight);
  } catch (e) {
    console.warn('Browser FaceDetector validation failed:', e);
    return null;
  }
}

async function validateStillImage(dataUrl) {
  const image = await loadImageFromDataUrl(dataUrl);
  const centerCrop = createCroppedImage(image, 0.82);

  const originalValid = await validateStillFrame(image);
  if (!originalValid) {
    return false;
  }

  if (!centerCrop) {
    return false;
  }

  const croppedValid = await validateStillFrame(centerCrop);
  return croppedValid;
}

window.validateCapturedFaceDataUrl = async function(dataUrl) {
  try {
    return await validateStillImage(dataUrl);
  } catch (e) {
    console.warn('validateCapturedFaceDataUrl error:', e);
    return false;
  }
};

function isValidFace(landmarks) {
  if (!landmarks || landmarks.length < 468) return false;

  const rightEye = landmarks[33];
  const leftEye = landmarks[263];
  const noseTip = landmarks[1];
  const chin = landmarks[152];
  const mouthLeft = landmarks[61];
  const mouthRight = landmarks[291];

  if (!rightEye || !leftEye || !noseTip || !chin || !mouthLeft || !mouthRight) {
    return false;
  }

  let minX = 1;
  let minY = 1;
  let maxX = 0;
  let maxY = 0;
  for (let i = 0; i < landmarks.length; i++) {
    const p = landmarks[i];
    if (p.x < minX) minX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.x > maxX) maxX = p.x;
    if (p.y > maxY) maxY = p.y;
  }

  const boxW = maxX - minX;
  const boxH = maxY - minY;
  const area = boxW * boxH;
  const centerX = (minX + maxX) / 2;
  const centerY = (minY + maxY) / 2;

  const aspectRatio = boxW / Math.max(boxH, 0.0001);

  if (boxW < 0.11 || boxH < 0.14) return false;
  if (area < 0.028 || area > 0.82) return false;
  if (aspectRatio < 0.30 || aspectRatio > 1.80) return false;
  if (Math.abs(centerX - 0.5) > 0.36) return false;
  if (Math.abs(centerY - 0.52) > 0.38) return false;

  const eyeDist = Math.hypot(leftEye.x - rightEye.x, leftEye.y - rightEye.y);
  if (eyeDist < 0.045 || eyeDist > 0.42) return false;

  // Eyes should be roughly level for a frontal selfie.
  if (Math.abs(leftEye.y - rightEye.y) > 0.13) return false;

  const eyeMidX = (leftEye.x + rightEye.x) / 2;
  const eyeMidY = (leftEye.y + rightEye.y) / 2;
  const eyeBandMinY = 0.24;
  const eyeBandMaxY = 0.52;
  if (Math.abs(noseTip.x - eyeMidX) > eyeDist * 0.95) return false;
  if (eyeMidY < eyeBandMinY || eyeMidY > eyeBandMaxY) return false;
  if (noseTip.y <= eyeMidY) return false;
  if (noseTip.y >= chin.y) return false;

  const mouthMidX = (mouthLeft.x + mouthRight.x) / 2;
  const mouthMidY = (mouthLeft.y + mouthRight.y) / 2;
  const mouthWidth = Math.hypot(mouthRight.x - mouthLeft.x, mouthRight.y - mouthLeft.y);
  if (mouthMidY <= noseTip.y) return false;
  if (Math.abs(mouthMidX - eyeMidX) > eyeDist * 1.05) return false;
  if (mouthWidth < eyeDist * 0.14 || mouthWidth > eyeDist * 1.80) return false;

  // Chin should sit below mouth clearly.
  if (chin.y <= mouthMidY) return false;

  return true;
}

function isValidCapturedFace(landmarks) {
  if (!isValidFace(landmarks)) return false;

  const forehead = landmarks[10];
  const leftCheek = landmarks[234];
  const rightCheek = landmarks[454];
  const rightEye = landmarks[33];
  const leftEye = landmarks[263];
  const noseTip = landmarks[1];
  const chin = landmarks[152];
  const mouthLeft = landmarks[61];
  const mouthRight = landmarks[291];

  if (!forehead || !leftCheek || !rightCheek) {
    return false;
  }

  let minX = 1;
  let minY = 1;
  let maxX = 0;
  let maxY = 0;
  for (let i = 0; i < landmarks.length; i++) {
    const p = landmarks[i];
    if (p.x < minX) minX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.x > maxX) maxX = p.x;
    if (p.y > maxY) maxY = p.y;
  }

  const boxW = maxX - minX;
  const boxH = maxY - minY;
  const area = boxW * boxH;
  const centerX = (minX + maxX) / 2;
  const centerY = (minY + maxY) / 2;
  const aspectRatio = boxW / Math.max(boxH, 0.0001);

  if (boxW < 0.16 || boxH < 0.20) return false;
  if (area < 0.055 || area > 0.72) return false;
  if (aspectRatio < 0.50 || aspectRatio > 1.30) return false;
  if (Math.abs(centerX - 0.5) > 0.26) return false;
  if (Math.abs(centerY - 0.52) > 0.30) return false;

  const eyeDist = Math.hypot(leftEye.x - rightEye.x, leftEye.y - rightEye.y);
  if (eyeDist < 0.07 || eyeDist > 0.32) return false;
  if (Math.abs(leftEye.y - rightEye.y) > 0.08) return false;

  const eyeMidX = (leftEye.x + rightEye.x) / 2;
  const eyeMidY = (leftEye.y + rightEye.y) / 2;
  const eyeBandMinY = 0.31;
  const eyeBandMaxY = 0.44;
  const mouthMidX = (mouthLeft.x + mouthRight.x) / 2;
  const mouthMidY = (mouthLeft.y + mouthRight.y) / 2;
  const mouthWidth = Math.hypot(mouthRight.x - mouthLeft.x, mouthRight.y - mouthLeft.y);
  const faceHeight = Math.hypot(chin.x - forehead.x, chin.y - forehead.y);
  const cheekWidth = Math.hypot(rightCheek.x - leftCheek.x, rightCheek.y - leftCheek.y);
  const eyeToBoxWidthRatio = eyeDist / Math.max(boxW, 0.0001);
  const cheekToBoxWidthRatio = cheekWidth / Math.max(boxW, 0.0001);
  const faceHeightToBoxRatio = faceHeight / Math.max(boxH, 0.0001);
  const noseHeightRatio = (noseTip.y - minY) / Math.max(boxH, 0.0001);
  const mouthHeightRatio = (mouthMidY - minY) / Math.max(boxH, 0.0001);

  if (forehead.y >= eyeMidY) return false;
  if (eyeMidY < eyeBandMinY || eyeMidY > eyeBandMaxY) return false;
  if (noseTip.y <= eyeMidY + 0.01 || noseTip.y >= chin.y - 0.03) return false;
  if (Math.abs(noseTip.x - eyeMidX) > eyeDist * 0.55) return false;
  if (mouthMidY <= noseTip.y + 0.015) return false;
  if (Math.abs(mouthMidX - eyeMidX) > eyeDist * 0.60) return false;
  if (mouthWidth < eyeDist * 0.30 || mouthWidth > eyeDist * 1.20) return false;
  if (chin.y <= mouthMidY + 0.02) return false;
  if (faceHeight < eyeDist * 1.35 || faceHeight > eyeDist * 3.20) return false;
  if (cheekWidth < eyeDist * 1.10 || cheekWidth > eyeDist * 2.40) return false;
  if (eyeToBoxWidthRatio < 0.22 || eyeToBoxWidthRatio > 0.52) return false;
  if (cheekToBoxWidthRatio < 0.55 || cheekToBoxWidthRatio > 0.98) return false;
  if (faceHeightToBoxRatio < 0.62 || faceHeightToBoxRatio > 0.98) return false;
  if (noseHeightRatio < 0.28 || noseHeightRatio > 0.68) return false;
  if (mouthHeightRatio < 0.45 || mouthHeightRatio > 0.82) return false;

  return true;
}

async function processFrame(timestamp) {
  if (!cameraStarted || !faceMesh) return;

  if (!targetVideo || !targetVideo.isConnected || targetVideo.readyState < 2 || targetVideo.videoWidth === 0) {
    targetVideo = findBestVideoElement(targetVideo);
  }

  if (!targetVideo) {
    consecutiveFaceFrames = 0;
    missedFaceFrames = 0;
    dispatchFaceDetected(false);
    animFrameId = requestAnimationFrame(processFrame);
    return;
  }

  if (processing) {
    animFrameId = requestAnimationFrame(processFrame);
    return;
  }

  if (typeof timestamp === 'number' && timestamp - lastProcessAt < PROCESS_INTERVAL_MS) {
    animFrameId = requestAnimationFrame(processFrame);
    return;
  }

  // Make sure the video is actually playing and has data.
  if (targetVideo.readyState < 2 || targetVideo.videoWidth === 0 || targetVideo.paused || targetVideo.ended) {
    targetVideo = findBestVideoElement(targetVideo);
    animFrameId = requestAnimationFrame(processFrame);
    return;
  }

  processing = true;
  lastProcessAt = typeof timestamp === 'number' ? timestamp : performance.now();
  try {
    await faceMesh.send({ image: targetVideo });
  } catch (e) {
    console.warn("FaceMesh send error:", e);
  }
  processing = false;

  if (cameraStarted) {
    animFrameId = requestAnimationFrame(processFrame);
  }
}

window.stopFaceDetection = function() {
  console.log("stopFaceDetection called");
  cameraStarted = false;
  consecutiveFaceFrames = 0;
  missedFaceFrames = 0;
  recentFaceValidity = [];
  targetVideo = null;
  dispatchFaceDetected(false);
  if (animFrameId) {
    cancelAnimationFrame(animFrameId);
    animFrameId = null;
  }
};

// ── Video diagnostics ─────────────────────────────────────────────────────────
function logVideoState(video, label) {
  if (!video) { console.log('[VideoDiag:' + label + '] no video element'); return; }
  var rect = video.getBoundingClientRect();
  var cs   = window.getComputedStyle(video);
  console.log('[VideoDiag:' + label + ']', {
    ua:         navigator.userAgent,
    screenWH:   screen.width + '×' + screen.height,
    innerWH:    window.innerWidth + '×' + window.innerHeight,
    dpr:        window.devicePixelRatio,
    streamWH:   video.videoWidth + '×' + video.videoHeight,
    readyState: video.readyState,
    rectWH:     rect.width.toFixed(1) + '×' + rect.height.toFixed(1),
    rectPos:    '(' + rect.left.toFixed(1) + ',' + rect.top.toFixed(1) + ')',
    cssWidth:   cs.width,
    cssHeight:  cs.height,
    objectFit:  cs.objectFit,
    transform:  cs.transform,
    position:   cs.position,
  });
}

// ── Ensure video element renders correctly ────────────────────────────────────
function fixVideoRendering(video) {
  if (!video) return;

  logVideoState(video, 'before-fix');

  var isIOS            = /iPhone|iPad|iPod/i.test(navigator.userAgent);
  var isPortraitScreen = window.innerHeight > window.innerWidth;
  var isLandscapeStream = video.videoWidth  > video.videoHeight;

  video.style.objectFit = 'cover';

  if (isPortraitScreen && isLandscapeStream && !isIOS) {
    // Android: browser returned a landscape stream (1280×720) even though we
    // requested portrait. CSS object-fit:cover alone would show only ~26% of
    // the frame width → heavy zoom. Fix: resize the element to landscape dims
    // and rotate -90° so it visually fills the portrait container correctly.
    //
    // Math:
    //   container = cw × ch  (e.g. 390×844)
    //   element   = ch × cw  (844×390) — swapped so it's landscape-sized
    //   rotate(-90deg) → visual size = cw × ch  ✓
    //   translate by ((cw-ch)/2, (ch-cw)/2) to re-center in the container
    var cw = window.innerWidth;   // e.g. 390
    var ch = window.innerHeight;  // e.g. 844
    var tx = (cw - ch) / 2;       // e.g. -227  (shifts left)
    var ty = (ch - cw) / 2;       // e.g. +227  (shifts down)
    video.style.width  = ch + 'px';
    video.style.height = cw + 'px';
    video.style.transformOrigin = 'center center';
    video.style.transform =
      'translateX(' + tx + 'px) translateY(' + ty + 'px) rotate(-90deg) scaleX(-1)';
    console.warn('[VideoFix] Android landscape→portrait rotation applied:',
      'stream=' + video.videoWidth + '×' + video.videoHeight,
      'screen=' + cw + '×' + ch);
  } else {
    // iOS (rotation handled by Safari internally) or portrait stream or desktop.
    // Reset any dimensions set by a prior landscape fix, then just mirror.
    video.style.width  = '';
    video.style.height = '';
    video.style.transformOrigin = '';
    video.style.transform = 'scaleX(-1)';
    if (isPortraitScreen && isLandscapeStream && isIOS) {
      console.log('[VideoFix] iOS landscape stream — Safari handles orientation, mirror only.');
    } else {
      console.log('[VideoFix] portrait stream, mirror only:',
        'stream=' + video.videoWidth + '×' + video.videoHeight,
        'screen=' + window.innerWidth + '×' + window.innerHeight);
    }
  }

  logVideoState(video, 'after-fix');
}

// Re-run fix on orientation change (user rotates device)
window.addEventListener('orientationchange', function() {
  setTimeout(function() {
    if (targetVideo) {
      console.log('[VideoFix] re-running after orientationchange');
      fixVideoRendering(targetVideo);
    }
  }, 400);
});

window.startFaceDetection = function(videoElement) {
  console.log("startFaceDetection called, element:", videoElement?.tagName);

  if (cameraStarted) {
    console.log("Already started, skipping");
    return;
  }

  if (!videoElement || videoElement.tagName !== 'VIDEO') {
    console.error("startFaceDetection: invalid video element");
    return;
  }

  targetVideo = findBestVideoElement(videoElement);
  cameraStarted = true;
  consecutiveFaceFrames = 0;
  missedFaceFrames = 0;
  recentFaceValidity = [];
  processing = false;
  lastDetectedState = false;
  lastProcessAt = 0;

  // Initialize FaceMesh if not already done
  if (!faceMesh) {
    faceMesh = createFaceMeshInstance();

    faceMesh.onResults((results) => {
      let faceValid = false;
      if (results.multiFaceLandmarks && results.multiFaceLandmarks.length > 0) {
        faceValid = isValidFace(results.multiFaceLandmarks[0]);
      }

      if (faceValid) {
        consecutiveFaceFrames++;
        missedFaceFrames = 0;
      } else {
        consecutiveFaceFrames = 0;
        missedFaceFrames++;
      }

      recentFaceValidity.push(faceValid);
      if (recentFaceValidity.length > DETECTION_WINDOW_SIZE) {
        recentFaceValidity.shift();
      }

      const validInWindow = recentFaceValidity.reduce((sum, val) => sum + (val ? 1 : 0), 0);

      const canAcquireByWindow = recentFaceValidity.length >= DETECTION_WINDOW_SIZE && validInWindow >= ACQUIRE_VALID_IN_WINDOW;
      const canAcquireByConsecutive = consecutiveFaceFrames >= ACQUIRE_CONSECUTIVE_FRAMES;
      const canAcquire = faceValid && (canAcquireByConsecutive || canAcquireByWindow);

      let detected = lastDetectedState;
      if (!detected) {
        // Do not re-acquire from stale window values if current frame is invalid.
        detected = canAcquire;
      } else {
        // Release immediately when the current frame is no longer a valid face.
        const lostByCurrentFrame = !faceValid;
        const lostByMissed = missedFaceFrames >= RELEASE_MISSED_FRAMES;
        const lostByWindow = recentFaceValidity.length >= DETECTION_WINDOW_SIZE && validInWindow < RELEASE_VALID_IN_WINDOW;
        detected = !(lostByCurrentFrame || lostByMissed || lostByWindow);
      }

      dispatchFaceDetected(detected);
    });

    console.log("FaceMesh model initializing...");
  }

  // Wait for the video to be ready, then start the frame loop
  function tryStart() {
    if (!cameraStarted) return;

    targetVideo = findBestVideoElement(targetVideo);
    if (targetVideo && targetVideo.readyState >= 2 && targetVideo.videoWidth > 0) {
      console.log("Video ready, starting face detection loop. Size:",
        targetVideo.videoWidth, "x", targetVideo.videoHeight);
      fixVideoRendering(targetVideo);
      animFrameId = requestAnimationFrame(processFrame);
    } else {
      const rs = targetVideo ? targetVideo.readyState : "none";
      console.log("Waiting for video to be ready... readyState:", rs);
      setTimeout(tryStart, 300);
    }
  }

  tryStart();
};