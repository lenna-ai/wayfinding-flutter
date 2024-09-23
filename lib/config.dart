// Your Situm user and API Key.
// From 3.1.0 version onwards, situmUser is not needed anymore.
// const situmUser = "YOUR-SITUM-USER";
const situmApiKey =
    "7ad91228d0607db889fa4d69c08b2c491be1d7f4887b88348828063ca963d8d2";

// Set here the building identifier you want on the map.
const buildingIdentifier = "15867";
// Alternatively, you can set an identifier that allows you to remotely configure all map settings.
// For now, you need to contact Situm to obtain yours.
const remoteIdentifier = null;

/// A String parameter that allows you to specify which domain will be displayed inside our webview.
/// Take a look at [MapViewConfiguration.viewerDomain].
const viewerDomain = "https://map-viewer.situm.com";

// Set here the API which you will use to retrieve the cartography from.
// Take a look at [MapViewConfiguration.apiDomain] and [SitumSdk.setDashboardURL] to learn how to implement it.
//const apiDomain = "https://dashboard.situm.com";