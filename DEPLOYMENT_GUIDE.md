# 🚀 Quick Deployment Guide - Minix Web App

## For New Deployment

### 1. Update Version Numbers

**File: `web/index.html` (Line 82)**
```javascript
const APP_VERSION = '1.0.1';  // 👈 Change this
```

**File: `web/service-worker.js` (Line 5)**
```javascript
const CACHE_VERSION = '1.0.1';  // 👈 Must match above
```

### 2. Enable Auto-Update

**File: `web/index.html` (Line 83)**
```javascript
const AUTO_UPDATE_ENABLED = true;  // 👈 Set to true for production
```

### 3. Build

```bash
flutter build web --release
```

### 4. Deploy

Upload everything from `build/web/` folder to your hosting service.

## What Happens Next?

When users visit your site:
1. ✅ If they have old version → Auto-update kicks in
2. ✅ Caches are cleared automatically
3. ✅ Page reloads with new version
4. ✅ User sees updated app!

## Testing Locally

```bash
# 1. Run in development mode
flutter run -d chrome

# 2. Change version to '1.0.1'
# 3. Set AUTO_UPDATE_ENABLED = true
# 4. Hot reload or restart
# 5. Check console for update logs
```

## Version Numbering

Use semantic versioning:
- **Major**: 1.x.x (Breaking changes)
- **Minor**: x.1.x (New features)
- **Patch**: x.x.1 (Bug fixes)

Examples:
- Bug fix: 1.0.0 → 1.0.1
- New feature: 1.0.1 → 1.1.0
- Breaking change: 1.1.0 → 2.0.0

## Important Notes

⚠️ **Both version numbers must match!**
- `index.html` APP_VERSION
- `service-worker.js` CACHE_VERSION

⚠️ **Development mode:**
- Set `AUTO_UPDATE_ENABLED = false` when developing
- Prevents reload loops during development

⚠️ **Production mode:**
- Set `AUTO_UPDATE_ENABLED = true` before building
- Users will get automatic updates

## Quick Checklist

- [ ] Updated `APP_VERSION` in `index.html`
- [ ] Updated `CACHE_VERSION` in `service-worker.js`
- [ ] Set `AUTO_UPDATE_ENABLED = true`
- [ ] Ran `flutter build web --release`
- [ ] Deployed `build/web/` folder

## That's It! 🎉

Your users will automatically get the new version when they next visit your site!

---

For detailed information, see `WEB_AUTO_UPDATE_README.md`
