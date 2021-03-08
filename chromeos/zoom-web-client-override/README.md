# Zoom Web Client Override
This Chrome extension streamlines the user experience of joining Zoom meetings via the Zoom Web Client on Chrome OS devices. Once installed, Zoom meeting URLs will automatically launch the Zoom Web Client within Google Chrome instead of launching the Zoom Chrome OS app.

Motivation
----------
We've found the performance of the Zoom Web Client on Chrome OS devices to be a bit better than the Zoom Chrome OS app.

However, when a user clicks on a Zoom meeting URL, the Zoom Chrome OS app automatically launches if it's installed or the user is prompted to install the app if it's not already installed.

How does this extension work?
----------------------------
This Chrome extension uses the [chrome.declarativeNetRequest](https://developer.chrome.com/docs/extensions/reference/declarativeNetRequest) API to transform Zoom meeting URLs to the equivalent Zoom Web Client URL and automatically redirects users to join Zoom meetings via the Zoom Web Client.

Quick start
-----------
1. Open the Google Chrome extensions page `chrome://extensions`
2. In the upper right corner, toggle on `Developer mode`
3. Click `Load unpacked`
4. Browse to this folder and click open

Deploying to your Chrome OS fleet
---------------------------------
1. Archive `background.js`, `manifest.json`, and `rules.json` into a zip file
2. Register as a [Chrome Web Store developer](https://developer.chrome.com/docs/webstore/register/)
3. Log into the [developer console](https://chrome.google.com/webstore/devconsole)
4. Add a new item
5. Go to the package tab and upload the zip file
6. Go to the Payments & distribution tab and set the Visibility to Private
7. Complete the remaining required store listing details
8. Submit for review (it may take a few minutes to be automatically approved)
9. Copy the Chrome extension ID and deploy the extension via the Google Admin console.
