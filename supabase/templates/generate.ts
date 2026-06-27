/**
 * Generates the branded Supabase Auth email templates from the shared
 * Cosmic Fit email theme, so they stay byte-for-byte consistent with the
 * transactional emails sent by the edge functions.
 *
 * These templates are referenced from `supabase/config.toml`
 * (`[auth.email.template.*]`). They only take effect when Supabase Auth sends
 * the corresponding email; the app's primary login uses the custom OTP flow in
 * the `send-otp` edge function. Regenerate after any branding change:
 *
 *   deno run --allow-read --allow-write --allow-env supabase/templates/generate.ts
 *
 * Supabase substitutes Go template variables such as {{ .ConfirmationURL }},
 * {{ .Token }}, {{ .Email }} and {{ .NewEmail }} at send time.
 */
import {
  button,
  codeBox,
  fineprint,
  heading,
  paragraph,
  renderEmail,
} from "../functions/_shared/email-theme.ts";

const ignoreNote =
  "If you didn't request this, you can safely ignore this email.";

interface Template {
  file: string;
  title: string;
  preheader: string;
  content: string;
}

const templates: Template[] = [
  {
    file: "confirmation.html",
    title: "Confirm your email — Cosmic Fit",
    preheader: "Confirm your email to start your Cosmic Fit journey.",
    content: `
      ${heading("Confirm your email")}
      ${paragraph("Welcome to Cosmic Fit. Confirm your email address to finish setting up your account.", { muted: true })}
      <div style="height:20px; line-height:20px;">&nbsp;</div>
      ${button("{{ .ConfirmationURL }}", "Confirm email")}
      <div style="height:18px; line-height:18px;">&nbsp;</div>
      ${fineprint(ignoreNote)}
    `,
  },
  {
    file: "magic_link.html",
    title: "Sign in to Cosmic Fit",
    preheader: "Your secure sign-in link for Cosmic Fit.",
    content: `
      ${heading("Sign in to Cosmic Fit")}
      ${paragraph("Tap the button below to sign in. This link works once and expires shortly.", { muted: true })}
      <div style="height:20px; line-height:20px;">&nbsp;</div>
      ${button("{{ .ConfirmationURL }}", "Sign in")}
      <div style="height:18px; line-height:18px;">&nbsp;</div>
      ${fineprint(ignoreNote)}
    `,
  },
  {
    file: "recovery.html",
    title: "Reset your password — Cosmic Fit",
    preheader: "Reset your Cosmic Fit password.",
    content: `
      ${heading("Reset your password")}
      ${paragraph("We received a request to reset your password. Tap below to choose a new one.", { muted: true })}
      <div style="height:20px; line-height:20px;">&nbsp;</div>
      ${button("{{ .ConfirmationURL }}", "Reset password")}
      <div style="height:18px; line-height:18px;">&nbsp;</div>
      ${fineprint(ignoreNote)}
    `,
  },
  {
    file: "invite.html",
    title: "You're invited to Cosmic Fit",
    preheader: "You've been invited to Cosmic Fit.",
    content: `
      ${heading("You're invited")}
      ${paragraph("You've been invited to join Cosmic Fit — your style, written in the stars. Accept your invitation to get started.", { muted: true })}
      <div style="height:20px; line-height:20px;">&nbsp;</div>
      ${button("{{ .ConfirmationURL }}", "Accept invitation")}
    `,
  },
  {
    file: "email_change.html",
    title: "Confirm your new email — Cosmic Fit",
    preheader: "Confirm the change to your Cosmic Fit email address.",
    content: `
      ${heading("Confirm your email change")}
      ${paragraph("Confirm that you'd like to change your Cosmic Fit email from {{ .Email }} to {{ .NewEmail }}.", { muted: true })}
      <div style="height:20px; line-height:20px;">&nbsp;</div>
      ${button("{{ .ConfirmationURL }}", "Confirm change")}
      <div style="height:18px; line-height:18px;">&nbsp;</div>
      ${fineprint(ignoreNote)}
    `,
  },
  {
    file: "email_otp.html",
    title: "Your Cosmic Fit verification code",
    preheader: "{{ .Token }} is your Cosmic Fit verification code.",
    content: `
      ${heading("Your verification code")}
      ${paragraph("Enter this code to continue.", { muted: true })}
      ${codeBox("{{ .Token }}")}
      <div style="height:16px; line-height:16px;">&nbsp;</div>
      ${fineprint(ignoreNote)}
    `,
  },
];

const outDir = new URL("./", import.meta.url);

for (const t of templates) {
  const html = renderEmail({
    content: t.content,
    title: t.title,
    preheader: t.preheader,
  });
  await Deno.writeTextFile(new URL(t.file, outDir), html + "\n");
  console.log(`generated supabase/templates/${t.file}`);
}
