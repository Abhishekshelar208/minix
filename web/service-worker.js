// ==================== LAYER 2: SERVICE WORKER AUTO-UPDATE ====================
// Minix Service Worker - Network First, Cache Fallback Strategy
// Version: 1.0.0

const CACHE_VERSION = '1.0.0';
const CACHE_NAME = `minix-cache-v${CACHE_VERSION}`;
const OFFLINE_URL = '/';

// Files to cache immediately on install
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
];

console.log('🚀 Service Worker loading...');
console.log('📦 Cache name:', CACHE_NAME);

// ==================== INSTALL EVENT ====================
// Called when service worker is first installed
self.addEventListener('install', (event) => {
  console.log('⚙️ Service Worker installing...');
  
  event.waitUntil(
    (async () => {
      try {
        // Open cache
        const cache = await caches.open(CACHE_NAME);
        console.log('📦 Cache opened:', CACHE_NAME);
        
        // Pre-cache essential files
        console.log('💾 Pre-caching essential files...');
        await cache.addAll(PRECACHE_URLS);
        console.log('✅ Pre-cache complete');
        
        // Force immediate activation (skip waiting)
        await self.skipWaiting();
        console.log('⏭️ Skip waiting - immediate activation');
      } catch (error) {
        console.error('❌ Install error:', error);
      }
    })()
  );
});

// ==================== ACTIVATE EVENT ====================
// Called when service worker becomes active
self.addEventListener('activate', (event) => {
  console.log('🔄 Service Worker activating...');
  
  event.waitUntil(
    (async () => {
      try {
        // Delete old caches
        const cacheNames = await caches.keys();
        console.log('🗑️ Checking for old caches...');
        
        await Promise.all(
          cacheNames.map(cacheName => {
            if (cacheName !== CACHE_NAME) {
              console.log('   Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
        
        console.log('✅ Old caches deleted');
        
        // Take control of all pages immediately
        await self.clients.claim();
        console.log('👑 Claimed all clients');
        console.log('✅ Service Worker activated successfully');
      } catch (error) {
        console.error('❌ Activate error:', error);
      }
    })()
  );
});

// ==================== FETCH EVENT ====================
// Network First, Cache Fallback Strategy
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip chrome extensions and other protocols
  if (!url.protocol.startsWith('http')) {
    return;
  }

  event.respondWith(
    (async () => {
      try {
        // STRATEGY: Network First
        // Try to fetch from network first
        console.log('🌐 Fetching from network:', url.pathname);
        
        const networkResponse = await fetch(request);
        
        // If successful, cache the response for future use
        if (networkResponse && networkResponse.status === 200) {
          const cache = await caches.open(CACHE_NAME);
          
          // Only cache same-origin requests
          if (url.origin === location.origin) {
            console.log('💾 Caching:', url.pathname);
            cache.put(request, networkResponse.clone());
          }
        }
        
        return networkResponse;
      } catch (error) {
        // FALLBACK: If network fails, try cache
        console.log('📡 Network failed, trying cache:', url.pathname);
        
        const cachedResponse = await caches.match(request);
        
        if (cachedResponse) {
          console.log('✅ Serving from cache:', url.pathname);
          return cachedResponse;
        }
        
        // If both network and cache fail
        console.error('❌ Both network and cache failed for:', url.pathname);
        
        // For navigation requests, return offline page
        if (request.mode === 'navigate') {
          const offlineResponse = await caches.match(OFFLINE_URL);
          if (offlineResponse) {
            return offlineResponse;
          }
        }
        
        // Return a basic error response
        return new Response(
          JSON.stringify({ 
            error: 'Offline - Resource not available',
            url: url.pathname 
          }), 
          {
            status: 503,
            statusText: 'Service Unavailable',
            headers: { 'Content-Type': 'application/json' }
          }
        );
      }
    })()
  );
});

// ==================== MESSAGE EVENT ====================
// Handle messages from the main app
self.addEventListener('message', (event) => {
  console.log('📬 Service Worker received message:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('⏭️ Skip waiting requested');
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CLEAR_CACHE') {
    console.log('🗑️ Clear cache requested');
    event.waitUntil(
      caches.delete(CACHE_NAME).then(() => {
        console.log('✅ Cache cleared');
      })
    );
  }
});

// ==================== SYNC EVENT (Background Sync) ====================
// Handle background sync when connection is restored
self.addEventListener('sync', (event) => {
  console.log('🔄 Background sync event:', event.tag);
  
  if (event.tag === 'sync-data') {
    event.waitUntil(
      // Perform sync operations here
      Promise.resolve()
    );
  }
});

// ==================== PUSH EVENT (Push Notifications) ====================
// Handle push notifications (optional)
self.addEventListener('push', (event) => {
  console.log('🔔 Push notification received');
  
  const data = event.data ? event.data.json() : {};
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'Minix', {
      body: data.body || 'New update available',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png'
    })
  );
});

console.log('✅ Service Worker script loaded');
