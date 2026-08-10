# Rêverie App Store Website

This is the official website for the Rêverie iOS app, deployed on Vercel.

## URLs for App Store Submission

- **Main Website (Marketing URL):** https://reverie-app.com
- **Support URL:** https://reverie-app.com/support  
- **Privacy Policy:** https://reverie-app.com/privacy
- **Terms of Use:** https://reverie-app.com/terms

## Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm run start
```

## Pages

1. **Homepage** (`/`) - Main marketing page
2. **Support** (`/support`) - Technical support and FAQ
3. **Privacy Policy** (`/privacy`) - Privacy policy page
4. **Terms of Use** (`/terms`) - Terms of service page

## Deployment on Vercel

The simplest way to deploy this website is using [Vercel](https://vercel.com):

1. Push this repository to GitHub/GitLab/Bitbucket
2. Import the project in Vercel
3. Vercel will automatically detect Next.js and configure the build settings
4. Deploy!

## Custom Domain Setup

After deploying to Vercel, you can set up a custom domain:

1. Go to your Vercel project settings
2. Navigate to "Domains"
3. Add your domain (e.g., `reverie-app.com`)
4. Configure DNS settings as instructed by Vercel

## Updating URLs in iOS App

After deploying this website, update the URLs in the iOS app (`AboutView.swift`):

```swift
// Update these URLs to match your deployed website
private let supportURL = URL(string: "https://YOUR_DOMAIN/support")!
private let marketingURL = URL(string: "https://YOUR_DOMAIN")!
private let privacyPolicyURL = URL(string: "https://YOUR_DOMAIN/privacy")!
private let termsOfUseURL = URL(string: "https://YOUR_DOMAIN/terms")!
```