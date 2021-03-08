// Execute when the extension installs, updates or when Chrome updates
const onInstalled = function () {
  chrome.runtime.onInstalled.addListener(function () {
    if (chrome.runtime.lastError) {
      console.error(chrome.runtime.lastError.message);
    } else {
      try {
        main();
      } catch (error) {
        console.error(error);
      }
    }
  });
};

// Get operating system
const getPlatformInfo = async function () {
  const platform = new Promise((resolve, reject) => {
    chrome.runtime.getPlatformInfo(function (platformInfo) {
      if (chrome.runtime.lastError) {
        reject(chrome.runtime.lastError.message);
      } else {
        resolve(platformInfo.os);
      }
    });
  });

  return platform;
};

// Enables the static rule set, ruleset_1 from rules.json
const updateEnabledRulesets = async function () {
  const status = new Promise((resolve, reject) => {
    chrome.declarativeNetRequest.updateEnabledRulesets(
      { enableRulesetIds: ["ruleset_1"] },
      function () {
        if (chrome.runtime.lastError) {
          reject(chrome.runtime.lastError.message);
        } else {
          resolve();
        }
      }
    );
  });

  return status;
};

// Only activate the rule set on Chrome OS devices
const main = async function () {
  const os = await getPlatformInfo();
  if (os == "cros") {
    updateEnabledRulesets();
  }
};

main();
onInstalled();
