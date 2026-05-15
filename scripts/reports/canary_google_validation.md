# Canary Google Validation (Major Arcana - VAE Denoise)

Run ID: `20260514T103833Z`
Pipeline: `stabilityai/sd-vae-ft-mse` VAE encode/decode round-trip (1 pass, MPS)
Quality gate: `--min-psnr 25.0 --min-ssim 0.69`

Upload these **five** promoted Major Arcana assets to Google's checker:

1. `Cosmic Fit/Resources/Assets.xcassets/Cards/00-TheFool.imageset/00-TheFool.png` (PSNR 28.16, SSIM 0.7515)
2. `Cosmic Fit/Resources/Assets.xcassets/Cards/01-TheMagician.imageset/01-TheMagician.png` (PSNR 27.81, SSIM 0.7723)
3. `Cosmic Fit/Resources/Assets.xcassets/Cards/04-TheEmperor.imageset/04-TheEmperor.png` (PSNR 25.70, SSIM 0.7533)
4. `Cosmic Fit/Resources/Assets.xcassets/Cards/13-Death.imageset/13-Death.png` (PSNR 28.25, SSIM 0.6943)
5. `Cosmic Fit/Resources/Assets.xcassets/Cards/21-TheWorld.imageset/21-TheWorld.png` (PSNR 31.91, SSIM 0.8540)

Candidates (same pixels): `Cosmic Fit/Resources/.synthid_candidates/20260514T103833Z/`

After validating, update `scripts/reports/synthid_run_report.json` field `google_checker_validation`, then run full set with `--approve-full` using the same thresholds.
