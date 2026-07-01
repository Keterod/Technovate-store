importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBb3cD0HVg0-XU3JPVfxRz1xSz6w4PFHNo',
  authDomain: 'empresa-s.firebaseapp.com',
  projectId: 'empresa-s',
  storageBucket: 'empresa-s.firebasestorage.app',
  messagingSenderId: '346974235549',
  appId: '1:346974235549:web:b43c15b52416054276dd74',
});

const messaging = firebase.messaging();

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
