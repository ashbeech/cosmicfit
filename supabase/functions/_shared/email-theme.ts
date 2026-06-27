/**
 * Cosmic Fit — shared email branding.
 *
 * Single source of truth for the look and feel of every transactional email
 * the backend sends. Build the email-specific content with the helpers below
 * (`heading`, `paragraph`, `codeBox`, `button`, …) and wrap it in
 * `renderEmail(...)` so every message shares the same shell, palette, type and
 * footer. Keeping all emails on this layout is what guarantees brand
 * consistency.
 *
 * Palette and type mirror the in-app theme (`CosmicFitTheme.swift`) and the
 * web legal pages (`web/shared/legal.css`):
 *   - Cosmic Blue  #000210  (ink / night sky)
 *   - Cosmic Grey  #DEDEDE  (paper / content surface)
 *   - Cosmic Lilac #7E69E6  (accent)
 *   - PT Serif for display type, DM Sans for body/UI text.
 */

export const brand = {
  colors: {
    ink: "#000210", // Cosmic Blue — primary text + outer background
    paper: "#DEDEDE", // Cosmic Grey — content card surface
    lilac: "#7E69E6", // Cosmic Lilac — accent
    lilacLight: "#C4B6F8", // Lighter lilac
    inkSoft: "#595A62", // Muted ink (≈60% ink on paper) for secondary text
    inkFaint: "#6F7077", // Faint ink for small print
    hairline: "rgba(0,2,16,0.16)", // Subtle dividers on the paper card
  },
  fonts: {
    serif: `'PT Serif', Georgia, 'Times New Roman', serif`,
    sans: `'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif`,
  },
  tagline: "Your style, written in the stars.",
  supportEmail: "help@cosmicfit.app",
  websiteUrl: "https://cosmicfit.app",
  /** Hosted brand lockup (dark ink, for the light card). Overridable per-env. */
  logoUrl: (typeof Deno !== "undefined" && Deno.env.get("EMAIL_LOGO_URL")) ||
    "https://cosmicfit.app/assets/email/cosmicfit-logo.png",
} as const;

/** Serif display heading sitting on the paper card. */
export function heading(text: string): string {
  return `<h1 style="margin:0 0 14px; font-family:${brand.fonts.serif}; font-size:26px; line-height:1.2; font-weight:700; color:${brand.colors.ink}; letter-spacing:0.01em;">${text}</h1>`;
}

/** Small uppercase eyebrow label (DM Sans), used above a heading. */
export function eyebrow(text: string): string {
  return `<p style="margin:0 0 10px; font-family:${brand.fonts.sans}; font-size:13px; font-weight:700; letter-spacing:1.4px; text-transform:uppercase; color:${brand.colors.lilac};">${text}</p>`;
}

/** Body paragraph (DM Sans). */
export function paragraph(text: string, opts: { muted?: boolean; size?: number } = {}): string {
  const color = opts.muted ? brand.colors.inkSoft : brand.colors.ink;
  const size = opts.size ?? 16;
  return `<p style="margin:0 0 16px; font-family:${brand.fonts.sans}; font-size:${size}px; line-height:1.6; color:${color};">${text}</p>`;
}

/** Faint small-print line (DM Sans), e.g. expiry / ignore notices. */
export function fineprint(text: string): string {
  return `<p style="margin:0; font-family:${brand.fonts.sans}; font-size:13px; line-height:1.6; color:${brand.colors.inkFaint};">${text}</p>`;
}

/** Highlighted verification-code block with a dashed lilac border. */
export function codeBox(code: string): string {
  return `
  <div style="margin:4px 0 8px;">
    <div style="display:inline-block; padding:18px 40px; background-color:rgba(126,105,230,0.08); border-radius:14px; border:2px dashed ${brand.colors.lilac};">
      <span style="font-family:${brand.fonts.sans}; font-size:40px; font-weight:700; letter-spacing:12px; color:${brand.colors.ink}; padding-left:12px;">${code}</span>
    </div>
  </div>`;
}

/** Primary lilac call-to-action button. */
export function button(href: string, label: string): string {
  return `
  <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
    <tr>
      <td align="center" bgcolor="${brand.colors.lilac}" style="border-radius:10px;">
        <a href="${href}" target="_blank"
           style="display:inline-block; padding:15px 38px; font-family:${brand.fonts.sans}; font-size:16px; font-weight:600; color:#FFFFFF; text-decoration:none; border-radius:10px;">
          ${label}
        </a>
      </td>
    </tr>
  </table>`;
}

/** Thin divider rule on the paper card. */
export function divider(): string {
  return `<div style="height:1px; background-color:${brand.colors.hairline}; margin:8px 0;"></div>`;
}

interface RenderEmailOptions {
  /** Inner HTML for the message body (use the helpers above). */
  content: string;
  /** Hidden inbox preview text shown after the subject line. */
  preheader?: string;
  /** Document <title>; defaults to "Cosmic Fit". */
  title?: string;
  /** Center-align the body content (default true — suits short transactional emails). */
  centered?: boolean;
}

/**
 * Wraps email content in the branded Cosmic Fit shell: night-sky background,
 * light content card, logo lockup header and footer.
 */
export function renderEmail({
  content,
  preheader = "",
  title = "Cosmic Fit",
  centered = true,
}: RenderEmailOptions): string {
  const align = centered ? "center" : "left";

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="color-scheme" content="light only" />
  <meta name="supported-color-schemes" content="light only" />
  <title>${title}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700&family=PT+Serif:ital,wght@0,400;0,700;1,400&display=swap');
    body { margin:0; padding:0; width:100% !important; }
    a { color:${brand.colors.lilac}; }
    @media (max-width:480px) {
      .cf-card { width:100% !important; border-radius:0 !important; }
      .cf-pad { padding-left:24px !important; padding-right:24px !important; }
    }
  </style>
</head>
<body style="margin:0; padding:0; background-color:${brand.colors.ink}; font-family:${brand.fonts.sans};">
  <div style="display:none; max-height:0; overflow:hidden; opacity:0; color:transparent; font-size:1px; line-height:1px;">${preheader}&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;</div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:${brand.colors.ink};">
    <tr>
      <td align="center" style="padding:40px 16px;">
        <table role="presentation" class="cf-card" width="480" cellpadding="0" cellspacing="0" style="width:480px; max-width:480px; background-color:${brand.colors.paper}; border-radius:18px; overflow:hidden;">

          <!-- Brand lockup -->
          <tr>
            <td align="center" class="cf-pad" style="padding:40px 40px 8px;">
              <img src="${brand.logoUrl}" width="150" alt="Cosmic Fit"
                   style="display:block; width:150px; max-width:60%; height:auto; border:0;" />
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td align="${align}" class="cf-pad" style="padding:24px 40px 8px; text-align:${align};">
              ${content}
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" class="cf-pad" style="padding:28px 40px 36px;">
              <div style="border-top:1px solid ${brand.colors.hairline}; padding-top:20px;">
                <p style="margin:0 0 6px; font-family:${brand.fonts.serif}; font-style:italic; font-size:14px; color:${brand.colors.ink};">
                  ${brand.tagline}
                </p>
                <p style="margin:0; font-family:${brand.fonts.sans}; font-size:12px; line-height:1.6; color:${brand.colors.inkFaint};">
                  Need help? <a href="mailto:${brand.supportEmail}" style="color:${brand.colors.lilac}; text-decoration:none;">${brand.supportEmail}</a>
                </p>
              </div>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}
