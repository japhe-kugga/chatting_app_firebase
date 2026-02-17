importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyDuipYmYnoRbc5CS9TewnB2NyD16elrGFY",
  authDomain: "messageflutterapp-3124e.firebaseapp.com",
  projectId: "messageflutterapp-3124e",
  storageBucket: "messageflutterapp-3124e.appspot.com",
  messagingSenderId: "431753014905",
  appId: "1:431753014905:web:3ba627769f3b7828892ea8"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
