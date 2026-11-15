# ScreenTime invite website

This is a zero-dependency static site for ScreenTime friend invitation links.

An invite URL has this shape:

```text
https://YOUR-PROJECT.vercel.app/invite/PROFILE_UUID
```

## Before deploying

The Apple application identifier is already configured as:

```text
W4R225M7E2.com.AlbertC.ScreenTimeAppIOS
```

If the Apple Developer Team ID or app bundle identifier changes, update
`.well-known/apple-app-site-association`.

When an App Store or TestFlight link is available, replace `REPLACE_ME` in
`app.js`. Until then, the landing page only shows the **Open ScreenTime** button.

## Deploy through the Vercel website

1. Push this repository to GitHub.
2. In Vercel, select **Add New > Project** and import the repository.
3. Set **Root Directory** to `invite-site`.
4. Set **Framework Preset** to `Other`.
5. Leave the Build Command and Output Directory empty.
6. Select **Deploy**.

Vercel will provide a production URL similar to:

```text
https://screentime-invite.vercel.app
```

Use that exact hostname in the iOS Associated Domains entitlement and in
`AppConstants.inviteBaseURL`.

## Deploy with the Vercel CLI

From this directory, run:

```sh
npx vercel
npx vercel --prod
```

Follow the prompts and accept the current directory as the project root.

## Verify after deployment

Check that the Apple association file returns JSON without redirecting:

```sh
curl -i https://YOUR-PROJECT.vercel.app/.well-known/apple-app-site-association
```

Then open a test invitation containing a real profile UUID:

```text
https://YOUR-PROJECT.vercel.app/invite/00000000-0000-4000-8000-000000000000
```

Universal Links can take time to refresh because Apple retrieves the association
file through its own CDN. Reinstall the development build after adding the
Associated Domains entitlement.
