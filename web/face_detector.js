console.log("face_detector.js loaded");

let faceMesh = null;
let cameraStarted = false;
let animFrameId = null;
let targetVideo = null;

const DETECTION_WINDOW_SIZE = 10;
const ACQUIRE_CONSECUTIVE_FRAMES = 6;
const ACQUIRE_VALID_IN_WINDOW = 6;
const RELEASE_VALID_IN_WINDOW = 2;
const RELEASE_MISSED_FRAMES = 3;
let consecutiveFaceFrames = 0;
let missedFaceFrames = 0;
let processing = false;
let lastDetectedState = false;
let recentFaceValidity = [];

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

function isValidFace(landmarks) {
  if (!landmarks || landmarks.length < 468) return false;

  const rightEye = landmarks[33];
  const leftEye = landmarks[263];
  const noseTip = landmarks[1];
  const chin = landmarks[152];
  const forehead = landmarks[10];
  const mouthLeft = landmarks[61];
  const mouthRight = landmarks[291];
  const leftCheek = landmarks[234];
  const rightCheek = landmarks[454];

  if (!rightEye || !leftEye || !noseTip || !chin || !forehead || !mouthLeft || !mouthRight || !leftCheek || !rightCheek) {
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

  if (boxW < 0.16 || boxH < 0.20) return false;
  if (area < 0.055 || area > 0.74) return false;
  if (Math.abs(centerX - 0.5) > 0.27) return false;
  if (Math.abs(centerY - 0.50) > 0.30) return false;

  const eyeDist = Math.hypot(leftEye.x - rightEye.x, leftEye.y - rightEye.y);
  if (eyeDist < 0.08 || eyeDist > 0.36) return false;

  const faceHeight = Math.hypot(chin.x - forehead.x, chin.y - forehead.y);
  if (faceHeight < eyeDist * 1.20 || faceHeight > eyeDist * 3.4) return false;

  // Eyes should be roughly level for a frontal selfie.
  if (Math.abs(leftEye.y - rightEye.y) > 0.09) return false;

  const eyeMidX = (leftEye.x + rightEye.x) / 2;
  const eyeMidY = (leftEye.y + rightEye.y) / 2;
  if (Math.abs(noseTip.x - eyeMidX) > eyeDist * 0.55) return false;
  if (noseTip.y < eyeMidY + 0.01 || noseTip.y > chin.y - 0.03) return false;

  const mouthMidX = (mouthLeft.x + mouthRight.x) / 2;
  const mouthMidY = (mouthLeft.y + mouthRight.y) / 2;
  const mouthWidth = Math.hypot(mouthRight.x - mouthLeft.x, mouthRight.y - mouthLeft.y);
  if (mouthMidY <= noseTip.y + 0.015) return false;
  if (Math.abs(mouthMidX - eyeMidX) > eyeDist * 0.60) return false;
  if (mouthWidth < eyeDist * 0.30 || mouthWidth > eyeDist * 1.25) return false;

  const cheekWidth = Math.hypot(rightCheek.x - leftCheek.x, rightCheek.y - leftCheek.y);
  if (cheekWidth < eyeDist * 1.10 || cheekWidth > eyeDist * 2.60) return false;

  // Chin should sit below mouth clearly.
  if (chin.y <= mouthMidY + 0.02) return false;

  return true;
}

async function processFrame() {
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

  // Make sure the video is actually playing and has data.
  if (targetVideo.readyState < 2 || targetVideo.videoWidth === 0 || targetVideo.paused || targetVideo.ended) {
    targetVideo = findBestVideoElement(targetVideo);
    animFrameId = requestAnimationFrame(processFrame);
    return;
  }

  processing = true;
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

  // Initialize FaceMesh if not already done
  if (!faceMesh) {
    faceMesh = new FaceMesh({
      locateFile: (file) =>
        `https://cdn.jsdelivr.net/npm/@mediapipe/face_mesh/${file}`
    });

    faceMesh.setOptions({
      maxNumFaces: 1,
      refineLandmarks: true,
      minDetectionConfidence: 0.75,
      minTrackingConfidence: 0.75
    });

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
        // Release quickly to avoid stale "true" when a hand/phone covers the face.
        const lostByMissed = missedFaceFrames >= RELEASE_MISSED_FRAMES;
        const lostByWindow = recentFaceValidity.length >= DETECTION_WINDOW_SIZE && validInWindow < RELEASE_VALID_IN_WINDOW;
        detected = !(lostByMissed || lostByWindow);
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
      animFrameId = requestAnimationFrame(processFrame);
    } else {
      const rs = targetVideo ? targetVideo.readyState : "none";
      console.log("Waiting for video to be ready... readyState:", rs);
      setTimeout(tryStart, 300);
    }
  }

  tryStart();
};