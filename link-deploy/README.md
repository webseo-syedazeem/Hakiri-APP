# Hakkiri Links Deployment (`link-deploy`)

This folder contains the standalone web pages for the Hakkiri mobile app:
- **Support Page:** `/support` (Help center, FAQs, customer support email)
- **Marketing Page:** `/marketing` (App showcase, features, impromptu drills, voice coaches)
- **Privacy Policy:** `/privacy` (Official privacy policy for App Store / Play Store)
- **Delete Account Page:** `/delete-account` (Instructions on deleting account & data retention details)

---

## How to Deploy to Vercel

### Option 1: Via Vercel CLI (Recommended & Fastest)
In your terminal, navigate to this folder and deploy:
```bash
cd link-deploy
npx vercel --prod
```
*Follow the on-screen prompts. Once finished, Vercel will give you a live production URL (e.g. `https://hakkiri-links.vercel.app`).*

### Option 2: Via Vercel Dashboard
1. Go to [vercel.com](https://vercel.com)
2. Click **Add New...** → **Project**
3. Select or upload the `link-deploy` folder
4. Click **Deploy**

---

## Live Production Links

Your live URLs on Vercel:
- **Home / Marketing:** `https://hakkiriapp.vercel.app/`
- **Support & Help Center:** `https://hakkiriapp.vercel.app/support`
- **Privacy Policy:** `https://hakkiriapp.vercel.app/privacy`
- **Account & Data Deletion:** `https://hakkiriapp.vercel.app/delete-account`

You can paste these directly into App Store Connect and Google Play Console.
