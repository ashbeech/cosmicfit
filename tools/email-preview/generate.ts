/**
 * Generates local HTML previews for every Cosmic Fit email template.
 *
 *   deno run --allow-read --allow-write --allow-env tools/email-preview/generate.ts
 *
 * Then open tools/email-preview/index.html in a browser (or run the dev server below).
 */

// Set logo before theme modules read EMAIL_LOGO_URL at import time.
const logoUrl = new URL("../../web/assets/email/cosmicfit-logo.png", import.meta.url)
  .href;
Deno.env.set("EMAIL_LOGO_URL", logoUrl);

const { renderOtpEmail } = await import(
  "../../supabase/functions/_shared/otp-email.ts"
);
const {
  button,
  codeBox,
  fineprint,
  heading,
  paragraph,
  renderEmail,
} = await import("../../supabase/functions/_shared/email-theme.ts");

const outDir = new URL("./previews/", import.meta.url);
const assetsDir = new URL("./assets/", import.meta.url);
const logoSrc = new URL("../../web/assets/email/cosmicfit-logo.png", import.meta.url);

await Deno.mkdir(assetsDir, { recursive: true });
await Deno.copyFile(logoSrc, new URL("cosmicfit-logo.png", assetsDir));

/** Swap production logo URL for a path that works from the local preview server. */
function localiseLogo(html: string): string {
  return html.replaceAll(logoUrl, "../assets/cosmicfit-logo.png");
}

const ignoreNote =
  "If you didn't request this, you can safely ignore this email.";

interface Preview {
  id: string;
  label: string;
  subject: string;
  source: string;
  html: string;
}

const previews: Preview[] = [
  {
    id: "otp-login",
    label: "Login OTP (production)",
    subject: "Your Cosmic Fit login code",
    source: "supabase/functions/_shared/otp-email.ts → send-otp",
    html: renderOtpEmail("030156", "you@example.com"),
  },
  {
    id: "confirmation",
    label: "Email confirmation",
    subject: "Confirm your Cosmic Fit email",
    source: "supabase/templates/confirmation.html",
    html: renderEmail({
      title: "Confirm your email — Cosmic Fit",
      preheader: "Confirm your email to start your Cosmic Fit journey.",
      content: `
        ${heading("Confirm your email")}
        ${paragraph("Welcome to Cosmic Fit. Confirm your email address to finish setting up your account.", { muted: true })}
        <div style="height:20px; line-height:20px;">&nbsp;</div>
        ${button("https://cosmicfit.app/auth/confirm?token=sample", "Confirm email")}
        <div style="height:18px; line-height:18px;">&nbsp;</div>
        ${fineprint(ignoreNote)}
      `,
    }),
  },
  {
    id: "magic-link",
    label: "Magic link sign-in",
    subject: "Sign in to Cosmic Fit",
    source: "supabase/templates/magic_link.html",
    html: renderEmail({
      title: "Sign in to Cosmic Fit",
      preheader: "Your secure sign-in link for Cosmic Fit.",
      content: `
        ${heading("Sign in to Cosmic Fit")}
        ${paragraph("Tap the button below to sign in. This link works once and expires shortly.", { muted: true })}
        <div style="height:20px; line-height:20px;">&nbsp;</div>
        ${button("https://cosmicfit.app/auth/magic?token=sample", "Sign in")}
        <div style="height:18px; line-height:18px;">&nbsp;</div>
        ${fineprint(ignoreNote)}
      `,
    }),
  },
  {
    id: "recovery",
    label: "Password recovery",
    subject: "Reset your Cosmic Fit password",
    source: "supabase/templates/recovery.html",
    html: renderEmail({
      title: "Reset your password — Cosmic Fit",
      preheader: "Reset your Cosmic Fit password.",
      content: `
        ${heading("Reset your password")}
        ${paragraph("We received a request to reset your password. Tap below to choose a new one.", { muted: true })}
        <div style="height:20px; line-height:20px;">&nbsp;</div>
        ${button("https://cosmicfit.app/auth/recovery?token=sample", "Reset password")}
        <div style="height:18px; line-height:18px;">&nbsp;</div>
        ${fineprint(ignoreNote)}
      `,
    }),
  },
  {
    id: "invite",
    label: "Invite",
    subject: "You're invited to Cosmic Fit",
    source: "supabase/templates/invite.html",
    html: renderEmail({
      title: "You're invited to Cosmic Fit",
      preheader: "You've been invited to Cosmic Fit.",
      content: `
        ${heading("You're invited")}
        ${paragraph("You've been invited to join Cosmic Fit — your style, written in the stars. Accept your invitation to get started.", { muted: true })}
        <div style="height:20px; line-height:20px;">&nbsp;</div>
        ${button("https://cosmicfit.app/auth/invite?token=sample", "Accept invitation")}
      `,
    }),
  },
  {
    id: "email-change",
    label: "Email change",
    subject: "Confirm your new Cosmic Fit email",
    source: "supabase/templates/email_change.html",
    html: renderEmail({
      title: "Confirm your new email — Cosmic Fit",
      preheader: "Confirm the change to your Cosmic Fit email address.",
      content: `
        ${heading("Confirm your email change")}
        ${paragraph("Confirm that you'd like to change your Cosmic Fit email from you@example.com to new@example.com.", { muted: true })}
        <div style="height:20px; line-height:20px;">&nbsp;</div>
        ${button("https://cosmicfit.app/auth/email-change?token=sample", "Confirm change")}
        <div style="height:18px; line-height:18px;">&nbsp;</div>
        ${fineprint(ignoreNote)}
      `,
    }),
  },
  {
    id: "email-otp",
    label: "Supabase Auth OTP",
    subject: "Your Cosmic Fit verification code",
    source: "supabase/templates/email_otp.html",
    html: renderEmail({
      title: "Your Cosmic Fit verification code",
      preheader: "030156 is your Cosmic Fit verification code.",
      content: `
        ${heading("Your verification code")}
        ${paragraph("Enter this code to continue.", { muted: true })}
        ${codeBox("030156")}
        <div style="height:16px; line-height:16px;">&nbsp;</div>
        ${fineprint(ignoreNote)}
      `,
    }),
  },
];

await Deno.mkdir(outDir, { recursive: true });

const manifest: Array<{ id: string; label: string; subject: string; source: string; file: string }> = [];

for (const p of previews) {
  const file = `${p.id}.html`;
  await Deno.writeTextFile(new URL(file, outDir), localiseLogo(p.html) + "\n");
  manifest.push({
    id: p.id,
    label: p.label,
    subject: p.subject,
    source: p.source,
    file,
  });
  console.log(`generated previews/${file}`);
}

await Deno.writeTextFile(
  new URL("manifest.json", outDir),
  JSON.stringify(manifest, null, 2) + "\n",
);

console.log(`\n${manifest.length} previews ready. Open tools/email-preview/index.html`);
