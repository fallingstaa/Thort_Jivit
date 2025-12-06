
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");
const { promisify } = require("util");
const { randomUUID } = require("crypto");

admin.initializeApp();
const execAsync = promisify(exec);

/**
 * Cloud Function to merge video URLs into a single video file using FFmpeg
 * POST /mergeVideos
 * Body: { videoUrls: ["url1", "url2", "url3"], weekId: "week123" }
 */
exports.mergeVideos = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(200).send();
    return;
  }

  try {
    console.log("[MERGE] Received request body:", JSON.stringify(req.body));
    
    const { videoUrls, weekId, targetDuration = 30 } = req.body;

    if (!videoUrls || !Array.isArray(videoUrls) || videoUrls.length === 0) {
      console.error("[MERGE] Invalid videoUrls");
      return res.status(400).json({ success: false, error: "videoUrls array is required" });
    }

    console.log(`[MERGE] Starting merge of ${videoUrls.length} videos for week ${weekId} with target duration ${targetDuration}s`);

    // Create temp directory
    const tempDir = path.join(os.tmpdir(), `merge_${Date.now()}`);
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    // Download videos
    const downloadedPaths = [];
    for (let i = 0; i < videoUrls.length; i++) {
      const url = videoUrls[i];
      try {
        console.log(`[MERGE] Downloading video ${i + 1}/${videoUrls.length}`);
        const response = await axios.get(url, { responseType: "arraybuffer" });
        const filePath = path.join(tempDir, `video_${i}.mp4`);
        fs.writeFileSync(filePath, response.data);
        downloadedPaths.push(filePath);
        console.log(`[MERGE] Downloaded video ${i + 1} to ${filePath}`);
      } catch (err) {
        console.error(`[MERGE] Error downloading video ${i}:`, err.message);
        fs.rmSync(tempDir, { recursive: true, force: true });
        return res.status(400).json({ success: false, error: `Failed to download video ${i}: ${err.message}` });
      }
    }

    // Create concat demuxer file
    const concatFilePath = path.join(tempDir, "concat.txt");
    console.log(`[MERGE] Creating concat file with ${downloadedPaths.length} videos`);

    // Create concat file with all videos
    const concatContent = downloadedPaths.map((p) => `file '${p}'`).join("\n");
    fs.writeFileSync(concatFilePath, concatContent);
    console.log(`[MERGE] Created concat file with ${downloadedPaths.length} videos`);

    // Merge using FFmpeg
    const outputPath = path.join(tempDir, `recap_${Date.now()}.mp4`);
    console.log(`[MERGE] Starting FFmpeg merge to ${outputPath}`);

    try {
      // Run FFmpeg to merge videos
      const ffmpegCommand = `ffmpeg -f concat -safe 0 -i "${concatFilePath}" -c copy -y "${outputPath}"`;
      console.log(`[MERGE] Executing: ${ffmpegCommand}`);
      
      const { stdout, stderr } = await execAsync(ffmpegCommand, { 
        maxBuffer: 50 * 1024 * 1024, // 50MB buffer
        timeout: 300000, // 5 minute timeout
      });
      
      console.log(`[MERGE] FFmpeg completed successfully`);

      // Upload merged video to Firebase Storage
      const bucket = admin.storage().bucket();
      const uid = req.query.uid || "unknown";
      const storageFileName = `recaps/${uid}/recap_${weekId}_${Date.now()}.mp4`;
      const file = bucket.file(storageFileName);

      console.log(`[MERGE] Uploading merged video to Storage: ${storageFileName}`);

      // Create a token for downloading
      const downloadToken = randomUUID();

      await bucket.upload(outputPath, {
        destination: storageFileName,
        metadata: {
          cacheControl: "public, max-age=3600",
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
          },
        },
      });

      // Build download URL
      const encodedPath = encodeURIComponent(storageFileName);
      const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;

      console.log(`[MERGE] Upload successful. URL: ${url.substring(0, 50)}...`);

      // Cleanup temp files
      fs.rmSync(tempDir, { recursive: true, force: true });

      return res.status(200).json({
        success: true,
        recapUrl: url,
        message: "Videos merged successfully",
        clipsCount: videoUrls.length,
      });
    } catch (ffmpegErr) {
      console.error("[MERGE] FFmpeg error:", ffmpegErr);
      fs.rmSync(tempDir, { recursive: true, force: true });
      return res.status(500).json({ success: false, error: `FFmpeg error: ${ffmpegErr.message}` });
    }
  } catch (error) {
    console.error("[MERGE] General error:", error);
    return res.status(500).json({ success: false, error: `Error: ${error.message}` });
  }
});

console.log("✓ Cloud Functions loaded: mergeVideos");
