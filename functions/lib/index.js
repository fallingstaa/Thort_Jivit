
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
  // Basic CORS for web calls (allow auth header for Firebase ID tokens)
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(200).send();
    return;
  }

  try {
    const { videoUrls, weekId, uid } = req.body;

    if (!videoUrls || !Array.isArray(videoUrls) || videoUrls.length === 0) {
      return res.status(400).json({ error: "videoUrls array is required" });
    }

    console.log(`[MERGE] Starting merge of ${videoUrls.length} videos for week ${weekId}`);

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
        return res.status(400).json({ error: `Failed to download video ${i}: ${err.message}` });
      }
    }

    // Create concat demuxer file
    const concatFilePath = path.join(tempDir, "concat.txt");
    const concatContent = downloadedPaths.map((p) => `file '${p}'`).join("\n");
    fs.writeFileSync(concatFilePath, concatContent);
    console.log(`[MERGE] Created concat file with ${downloadedPaths.length} videos`);

    // First, merge videos without audio to get the final duration
    const videoOnlyPath = path.join(tempDir, `video_only_${Date.now()}.mp4`);
    console.log(`[MERGE] Merging videos without audio first to ${videoOnlyPath}`);

    try {
      const videoMergeCommand = `ffmpeg -f concat -safe 0 -i "${concatFilePath}" -c copy -an -y "${videoOnlyPath}" 2>&1`;
      console.log(`[MERGE] Executing: ${videoMergeCommand}`);
      await execAsync(videoMergeCommand, { 
        maxBuffer: 50 * 1024 * 1024,
        timeout: 300000,
      });
      console.log(`[MERGE] Videos merged successfully`);

      // Get video duration
      const durationCommand = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${videoOnlyPath}"`;
      const { stdout: durationOutput } = await execAsync(durationCommand);
      const videoDuration = parseFloat(durationOutput.trim());
      console.log(`[MERGE] Video duration: ${videoDuration}s`);

      // Get random MP3 from Firebase Storage
      const bucket = admin.storage().bucket();
      const [musicFiles] = await bucket.getFiles({ prefix: "music_library/" });
      
      if (musicFiles.length === 0) {
        console.log(`[MERGE] No background music found, using video without audio`);
        // Just use the video without music
        const outputPath = videoOnlyPath;
        
        // Upload to storage
        const storageFileName = `recaps/${uid || "unknown"}/recap_${weekId}_${Date.now()}.mp4`;
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

        const encodedPath = encodeURIComponent(storageFileName);
        const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;

        fs.rmSync(tempDir, { recursive: true, force: true });

        return res.status(200).json({
          success: true,
          recapUrl: url,
          message: "Videos merged successfully (no background music)",
          clipsCount: videoUrls.length,
        });
      }

      // Pick random MP3
      const randomIndex = Math.floor(Math.random() * musicFiles.length);
      const randomMusicFile = musicFiles[randomIndex];
      console.log(`[MERGE] Selected random music: ${randomMusicFile.name}`);

      // Download the MP3
      const musicPath = path.join(tempDir, "music.mp3");
      await randomMusicFile.download({ destination: musicPath });
      console.log(`[MERGE] Downloaded music to ${musicPath}`);

      // Get music duration
      const musicDurationCommand = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${musicPath}"`;
      const { stdout: musicDurationOutput } = await execAsync(musicDurationCommand);
      const musicDuration = parseFloat(musicDurationOutput.trim());
      console.log(`[MERGE] Music duration: ${musicDuration}s`);

      // Calculate how many loops needed
      const loopsNeeded = Math.ceil(videoDuration / musicDuration);
      console.log(`[MERGE] Need ${loopsNeeded} loops of music to cover ${videoDuration}s of video`);

      // Create looped audio that matches video duration
      const loopedAudioPath = path.join(tempDir, "looped_audio.mp3");
      const loopAudioCommand = `ffmpeg -stream_loop ${loopsNeeded - 1} -i "${musicPath}" -t ${videoDuration} -c copy -y "${loopedAudioPath}" 2>&1`;
      console.log(`[MERGE] Creating looped audio: ${loopAudioCommand}`);
      await execAsync(loopAudioCommand, {
        maxBuffer: 50 * 1024 * 1024,
        timeout: 120000,
      });
      console.log(`[MERGE] Looped audio created`);

      // Merge video with looped audio
      const outputPath = path.join(tempDir, `recap_${Date.now()}.mp4`);
      const finalMergeCommand = `ffmpeg -i "${videoOnlyPath}" -i "${loopedAudioPath}" -c:v copy -c:a aac -shortest -y "${outputPath}" 2>&1`;
      console.log(`[MERGE] Merging video with looped audio: ${finalMergeCommand}`);
      await execAsync(finalMergeCommand, { 
        maxBuffer: 50 * 1024 * 1024,
        timeout: 300000,
      });
      
      console.log(`[MERGE] Final merge completed successfully`);

      // Upload merged video to Firebase Storage
      const storageFileName = `recaps/${uid || "unknown"}/recap_${weekId}_${Date.now()}.mp4`;
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
      return res.status(500).json({ error: `FFmpeg error: ${ffmpegErr.message}` });
    }
  } catch (error) {
    console.error("[MERGE] General error:", error);
    return res.status(500).json({ error: `Error: ${error.message}` });
  }
});

console.log("✓ Cloud Functions loaded: mergeVideos");

/**
 * Cloud Function to swap/replace music on an existing recap video.
 * POST /changeRecapMusic
 * Body: { recapUrl: string, musicFileName: string, weekId: string, uid: string }
 */
exports.changeRecapMusic = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(200).send();
    return;
  }

  try {
    const { recapUrl, musicFileName, weekId, uid } = req.body;

    if (!recapUrl || typeof recapUrl !== "string") {
      return res.status(400).json({ error: "recapUrl is required" });
    }
    if (!musicFileName || typeof musicFileName !== "string") {
      return res.status(400).json({ error: "musicFileName is required" });
    }

    console.log(`[MUSIC_SWAP] Replacing music for recap week ${weekId} using track ${musicFileName}`);

    const tempDir = path.join(os.tmpdir(), `music_swap_${Date.now()}`);
    fs.mkdirSync(tempDir, { recursive: true });

    // Download existing recap video
    const recapPath = path.join(tempDir, "recap_video.mp4");
    try {
      const response = await axios.get(recapUrl, { responseType: "arraybuffer" });
      fs.writeFileSync(recapPath, response.data);
      console.log(`[MUSIC_SWAP] Recap downloaded to ${recapPath}`);
    } catch (err) {
      console.error("[MUSIC_SWAP] Failed to download recap video", err.message);
      fs.rmSync(tempDir, { recursive: true, force: true });
      return res.status(400).json({ error: `Failed to download recap: ${err.message}` });
    }

    // Get recap duration
    const durationCommand = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${recapPath}"`;
    const { stdout: recapDurationOutput } = await execAsync(durationCommand);
    const recapDuration = parseFloat(recapDurationOutput.trim());
    console.log(`[MUSIC_SWAP] Recap duration: ${recapDuration}s`);

    const bucket = admin.storage().bucket();
    const musicStoragePath = `music_library/${musicFileName}`;
    const musicFile = bucket.file(musicStoragePath);

    const [exists] = await musicFile.exists();
    if (!exists) {
      console.error(`[MUSIC_SWAP] Music file not found: ${musicStoragePath}`);
      fs.rmSync(tempDir, { recursive: true, force: true });
      return res.status(404).json({ error: "Music file not found" });
    }

    // Download selected music
    const musicPath = path.join(tempDir, "music.mp3");
    await musicFile.download({ destination: musicPath });
    console.log(`[MUSIC_SWAP] Downloaded music to ${musicPath}`);

    // Get music duration
    const musicDurationCommand = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${musicPath}"`;
    const { stdout: musicDurationOutput } = await execAsync(musicDurationCommand);
    const musicDuration = parseFloat(musicDurationOutput.trim());
    console.log(`[MUSIC_SWAP] Music duration: ${musicDuration}s`);

    // Calculate loops needed
    const loopsNeeded = Math.ceil(recapDuration / musicDuration);
    console.log(`[MUSIC_SWAP] Looping music ${loopsNeeded} times to cover recap`);

    // Create looped audio
    const loopedAudioPath = path.join(tempDir, "looped_audio.mp3");
    const loopAudioCommand = `ffmpeg -stream_loop ${loopsNeeded - 1} -i "${musicPath}" -t ${recapDuration} -c copy -y "${loopedAudioPath}" 2>&1`;
    await execAsync(loopAudioCommand, {
      maxBuffer: 50 * 1024 * 1024,
      timeout: 120000,
    });
    console.log("[MUSIC_SWAP] Looped audio created");

    // Merge video with new audio (strip old audio, replace with new music)
    const outputPath = path.join(tempDir, `recap_music_swap_${Date.now()}.mp4`);
    const mergeCommand = `ffmpeg -i "${recapPath}" -i "${loopedAudioPath}" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest -y "${outputPath}" 2>&1`;
    await execAsync(mergeCommand, {
      maxBuffer: 50 * 1024 * 1024,
      timeout: 300000,
    });
    console.log("[MUSIC_SWAP] Merged video with new audio");

    // Upload to storage
    const storageFileName = `recaps/${uid || "unknown"}/recap_${weekId || "unknown"}_${Date.now()}.mp4`;
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

    const encodedPath = encodeURIComponent(storageFileName);
    const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;
    console.log(`[MUSIC_SWAP] Upload complete. URL: ${url.substring(0, 50)}...`);

    fs.rmSync(tempDir, { recursive: true, force: true });

    return res.status(200).json({
      success: true,
      recapUrl: url,
      message: "Music updated successfully",
      selectedMusic: musicFileName,
    });
  } catch (error) {
    console.error("[MUSIC_SWAP] Error:", error);
    return res.status(500).json({ error: `Error: ${error.message}` });
  }
});
