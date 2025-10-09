# 🔄 Minix Web App Auto-Update System

## Overview

This Flutter web app implements a **dual-layer auto-update system** that ensures users always see the latest version without manual cache clearing.

## 🏗️ Architecture

### Layer 1: HTML Version Control (`web/index.html`)
**Lines 79-208**

#### Configuration
```javascript
const APP_VERSION = '1.0.0';  // ⚙️ Update this when deploying new version
const AUTO_UPDATE_ENABLED = false;  // 🔧 Set to true in production
```

#### Features
- ✅ Stores version number in `localStorage`
- ✅ Compares stored version with current version on page load
- ✅ When version mismatch detected:
  - Clears all caches
  - Unregisters all service workers
  - Clears localStorage (except version info)
  - Forces hard reload
- ✅ 10-second cooldown to prevent reload loops
- ✅ Detailed console logging for debugging

#### How It Works
```
User loads page
     ↓
Check stored version vs current version
     ↓
Version match? → Continue loading
     ↓
Version mismatch?
     ↓
Clear caches & storage → Unregister service workers → Force reload
```

### Layer 2: Custom Service Worker (`web/service-worker.js`)

#### Strategy: Network First, Cache Fallback

```
Request received
     ↓
Try network first
     ↓
Success? → Cache response → Return
     ↓
Failure? → Check cache
     ↓
Found in cache? → Return cached
     ↓
Not found? → Return offline page
```

#### Features
- ✅ **Install**: Pre-caches essential files
- ✅ **Install**: Calls `skipWaiting()` for immediate activation
- ✅ **Activate**: Deletes old cache versions automatically
- ✅ **Activate**: Calls `clients.claim()` for instant control
- ✅ **Fetch**: Network-first strategy (always fresh data)
- ✅ **Fetch**: Cache fallback for offline support
- ✅ **Version-specific cache**: `minix-cache-v1.0.0`

## 📋 Deployment Workflow

### Step 1: Update Version Number

**In `web/index.html` (Line 82):**
```javascript
const APP_VERSION = '1.0.1';  // Increment version
```

**In `web/service-worker.js` (Line 5):**
```javascript
const CACHE_VERSION = '1.0.1';  // Must match index.html
```

### Step 2: Enable Auto-Update for Production

**In `web/index.html` (Line 83):**
```javascript
const AUTO_UPDATE_ENABLED = true;  // Enable in production
```

### Step 3: Build and Deploy

```bash
# Build web app
flutter build web --release

# The build output will be in build/web/
# Deploy build/web/ folder to your hosting service
```

### Step 4: Users Get Automatic Update

```
1. User loads old version (v1.0.0)
2. HTML detects version mismatch
3. Clears all caches and storage
4. Forces reload
5. User gets new version (v1.0.1)
```

## 🔍 Version Check Flow

### Development Mode (AUTO_UPDATE_ENABLED = false)
```
Page loads
   ↓
Check version → Log to console → Continue
   ↓
No update performed
```

### Production Mode (AUTO_UPDATE_ENABLED = true)
```
Page loads
   ↓
Check stored version
   ↓
Version mismatch?
   ↓
YES → Clear everything → Force reload
NO  → Continue normally
```

## 🛡️ Safety Features

### 1. Reload Loop Prevention
- 10-second cooldown between reloads
- Timestamp stored in `localStorage`
- Prevents infinite reload loops

### 2. Graceful Fallback
- If cache clearing fails, still attempts reload
- Error logging for debugging
- Version is updated even if update fails

### 3. Selective Storage Clearing
- Keeps version and timestamp during clear
- Other data is preserved if needed
- No data loss during updates

## 📊 Cache Strategy Details

### Network First Benefits
✅ Always tries to get fresh data  
✅ Falls back to cache if network fails  
✅ Perfect for frequently updated content  
✅ Provides offline support  

### Cache Management
- **Cache Name**: `minix-cache-v1.0.0`
- **Old caches**: Automatically deleted on activation
- **Pre-cached files**: Essential app files only
- **Dynamic caching**: All successful requests

## 🧪 Testing

### Test Auto-Update Locally

1. **Initial Load**
   ```bash
   flutter run -d chrome
   ```

2. **Update Version**
   - Change `APP_VERSION` to '1.0.1'
   - Set `AUTO_UPDATE_ENABLED = true`

3. **Reload Browser**
   - Open DevTools → Console
   - Watch for version check logs
   - Should see cache clearing messages

4. **Verify Update**
   ```javascript
   // In browser console:
   localStorage.getItem('minix_app_version')
   // Should show: "1.0.1"
   ```

### Test Service Worker

1. **Open DevTools → Application → Service Workers**
   - Verify service worker is registered
   - Check status: "activated and running"

2. **Check Cache**
   - Application → Cache Storage
   - Should see: `minix-cache-v1.0.0`

3. **Test Offline**
   - DevTools → Network → Offline
   - Refresh page → Should load from cache

## 📝 Console Logging

### Version Check Logs
```
🔍 Checking app version...
📱 Current version: 1.0.0
💾 Stored version: none
✅ Version is up to date
```

### Update Detection Logs
```
🔄 Version mismatch detected!
   Old: 1.0.0
   New: 1.0.1
🧹 Clearing caches and storage...
🗑️ Clearing caches...
   Deleting cache: minix-cache-v1.0.0
🔌 Unregistering service workers...
   Unregistering: /
🧹 Clearing storage...
🔄 Performing hard reload...
```

### Service Worker Logs
```
🚀 Service Worker loading...
📦 Cache name: minix-cache-v1.0.0
⚙️ Service Worker installing...
📦 Cache opened: minix-cache-v1.0.0
💾 Pre-caching essential files...
✅ Pre-cache complete
⏭️ Skip waiting - immediate activation
🔄 Service Worker activating...
🗑️ Checking for old caches...
✅ Old caches deleted
👑 Claimed all clients
✅ Service Worker activated successfully
```

## 🚀 Production Checklist

Before deploying to production:

- [ ] Update `APP_VERSION` in `index.html`
- [ ] Update `CACHE_VERSION` in `service-worker.js` (must match)
- [ ] Set `AUTO_UPDATE_ENABLED = true` in `index.html`
- [ ] Test version update flow locally
- [ ] Build with `flutter build web --release`
- [ ] Deploy `build/web/` folder
- [ ] Verify in production environment
- [ ] Check console logs for any errors

## 🔧 Configuration Reference

### index.html Configuration

| Variable | Default | Production | Description |
|----------|---------|------------|-------------|
| `APP_VERSION` | '1.0.0' | Increment | Current app version |
| `AUTO_UPDATE_ENABLED` | false | true | Enable auto-update |
| `VERSION_KEY` | 'minix_app_version' | No change | localStorage key |
| `RELOAD_COOLDOWN` | 10000 | No change | Cooldown in ms |

### service-worker.js Configuration

| Variable | Default | Production | Description |
|----------|---------|------------|-------------|
| `CACHE_VERSION` | '1.0.0' | Match index.html | Cache version |
| `CACHE_NAME` | 'minix-cache-v1.0.0' | Auto-generated | Cache identifier |
| `PRECACHE_URLS` | [array] | Customize | Files to pre-cache |

## 🎯 Benefits

### For Users
✅ Always see latest version automatically  
✅ No manual cache clearing needed  
✅ Smooth update experience  
✅ Offline support with cache fallback  
✅ Fast load times after first visit  

### For Developers
✅ Simple version management  
✅ No complex update logic in app code  
✅ Detailed logging for debugging  
✅ Prevention of reload loops  
✅ Safe fallback mechanisms  

## 🐛 Troubleshooting

### Users Not Getting Updates?

1. **Check `AUTO_UPDATE_ENABLED`**
   - Must be `true` in production

2. **Verify Version Numbers**
   - `index.html` APP_VERSION
   - `service-worker.js` CACHE_VERSION
   - Must be incremented and matching

3. **Check Browser Console**
   - Look for version check logs
   - Check for errors

### Reload Loops?

1. **Check Cooldown**
   - Default is 10 seconds
   - May need to increase for slow connections

2. **Clear Manually**
   ```javascript
   localStorage.clear();
   caches.keys().then(names => names.forEach(name => caches.delete(name)));
   ```

### Service Worker Not Updating?

1. **Hard refresh**: Ctrl+Shift+R (Cmd+Shift+R on Mac)
2. **DevTools**: Application → Service Workers → Unregister
3. **Incognito mode**: Test in fresh session

## 📚 Additional Resources

- [Service Workers MDN](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [Cache API MDN](https://developer.mozilla.org/en-US/docs/Web/API/Cache)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

## 🎉 Summary

This dual-layer system ensures:
- **Layer 1 (HTML)**: Catches version changes and forces hard updates
- **Layer 2 (Service Worker)**: Provides network-first caching and offline support

Users **always** get the latest version, and the app works offline! 🚀

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-09  
**Status**: ✅ Production Ready
