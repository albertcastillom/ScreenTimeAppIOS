// Replace this when the app has a public App Store or TestFlight URL.
const INSTALL_URL = "https://testflight.apple.com/join/REPLACE_ME";

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function inviteIDFromLocation() {
  const pathParts = window.location.pathname.split("/").filter(Boolean);

  if (
    pathParts.length === 2 &&
    pathParts[0] === "invite" &&
    UUID_PATTERN.test(pathParts[1])
  ) {
    return pathParts[1].toLowerCase();
  }

  // This query parameter is only for convenient local previewing.
  const previewID = new URLSearchParams(window.location.search).get("invite");
  return previewID && UUID_PATTERN.test(previewID)
    ? previewID.toLowerCase()
    : null;
}

function configureInvitePage() {
  const inviteID = inviteIDFromLocation();
  const actions = document.querySelector("#invite-actions");
  const invalidInvite = document.querySelector("#invalid-invite");
  const openAppLink = document.querySelector("#open-app-link");
  const installAppLink = document.querySelector("#install-app-link");
  const installNote = document.querySelector("#install-note");

  if (!inviteID) {
    invalidInvite.hidden = false;
    return;
  }

  actions.hidden = false;
  openAppLink.href = `com.albertcastillo.commit://invite/${inviteID}`;

  if (INSTALL_URL.includes("REPLACE_ME")) {
    installAppLink.hidden = true;
    installNote.hidden = false;
  } else {
    installAppLink.href = INSTALL_URL;
  }
}

configureInvitePage();
