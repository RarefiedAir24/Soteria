# Montebay.io Website

## 🎬 Video Background Setup

The homepage features an ocean waves with mountain video background. 

### Video File Requirements:
- **Format**: MP4 (primary) and WebM (fallback)
- **Location**: `assets/ocean-mountain.mp4` and `assets/ocean-mountain.webm`
- **Recommended specs**:
  - Resolution: 1920x1080 or higher
  - Duration: 10-30 seconds (will loop)
  - File size: Optimized for web (under 5MB if possible)
  - Codec: H.264 for MP4, VP9 for WebM

### Fallback Image:
- **Location**: `assets/ocean-mountain-fallback.jpg`
- **Size**: 1920x1080 or higher
- Used if video doesn't load

## 📁 File Structure

```
montebay-website/
├── index.html          # Homepage
├── styles.css          # Main stylesheet
├── script.js           # JavaScript
├── assets/
│   ├── ocean-mountain.mp4          # Video background (add your file)
│   ├── ocean-mountain.webm         # WebM version (optional)
│   └── ocean-mountain-fallback.jpg # Fallback image (add your file)
├── soteria.html        # Soteria app page (to be created)
├── support.html        # Support page (to be created)
├── privacy.html        # Privacy policy (to be created)
└── terms.html          # Terms of service (to be created)
```

## 🚀 Quick Start

1. **Add your video file**:
   - Place `ocean-mountain.mp4` in the `assets/` folder
   - (Optional) Add `ocean-mountain.webm` for better browser support
   - Add `ocean-mountain-fallback.jpg` as backup

2. **Test locally**:
   ```bash
   # Using Python
   python3 -m http.server 8000
   
   # Or using Node.js
   npx serve
   ```
   Then open: http://localhost:8000

3. **Deploy**:
   - **Netlify**: Drag and drop the folder
   - **GitHub Pages**: Push to repo and enable Pages
   - **Vercel**: Connect repo or drag and drop

## 🎨 Customization

### Colors (in styles.css):
- `--rever-blue`: #7DA2C8
- `--midnight-slate`: #1E1F23
- `--soft-graphite`: #6B7280
- `--cloud-white`: #F8F9FA

### Video Overlay:
Adjust the gradient overlay in `.video-overlay` to change the darkness/transparency over the video.

## 📱 Responsive

The site is fully responsive and works on:
- Desktop
- Tablet
- Mobile

## ✅ Next Steps

1. Add your ocean-mountain video file
2. Create additional pages (soteria.html, support.html, etc.)
3. Update contact email in footer
4. Deploy to hosting
5. Point montebay.io domain


