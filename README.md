# bancon

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.


## Offline Mode (Agent Screen)

The Agent Screen supports full offline mode for field data collection. Here’s how it works:

### How Offline Mode Works

- **Local Save:**
	- When you submit a new store, the data is always saved locally on your device, even if you are offline or have an unstable connection.
	- You will see a message indicating whether the store was saved offline or is syncing to the server.

- **Automatic Sync:**
	- The app continuously monitors your internet connection.
	- As soon as a connection is detected, all pending (offline) store records are automatically uploaded to the server (Supabase).
	- You do not need to take any manual action—sync happens in the background.

- **Pending Uploads Indicator:**
	- The Agent Screen displays the number of store records waiting to be synced.
	- This helps you track if there is any unsynced data on your device.

- **Data Safety:**
	- All unsynced data is stored securely in a local database on your device until it is successfully uploaded.
	- If a sync fails, the app will retry automatically when the connection is restored.

### User Experience

1. Fill out the store form as usual.
2. Submit the form. The app will show a message:
	 - If online: “Store saved and syncing to server!”
	 - If offline: “Store saved offline. Will sync when online.”
3. You can continue using the app and submitting more stores, even without internet.
4. When you regain connectivity, all pending stores are uploaded automatically.

No manual sync or export is required—just use the app normally!

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
