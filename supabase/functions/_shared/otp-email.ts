import {
  brand,
  button,
  codeBox,
  fineprint,
  heading,
  paragraph,
  renderEmail,
} from "./email-theme.ts";

export function renderOtpEmail(code: string, email: string): string {
  const deepLink = `cosmicfit://login?code=${encodeURIComponent(code)}&email=${
    encodeURIComponent(email)
  }`;

  const content = `
    ${heading("Your login code")}
    ${paragraph("Enter this code in the app to sign in.", { muted: true })}
    ${codeBox(code)}
    <div style="height:24px; line-height:24px;">&nbsp;</div>
    ${button(deepLink, "Open Cosmic Fit")}
    <div style="height:10px; line-height:10px;">&nbsp;</div>
    ${paragraph("Or enter the code manually in the app.", { muted: true, size: 13 })}
    <div style="height:8px; line-height:8px;">&nbsp;</div>
    ${
    fineprint(
      "This code expires in 10 minutes.<br />If you didn't request this, you can safely ignore it.",
    )
  }
  `;

  return renderEmail({
    content,
    title: "Your Cosmic Fit login code",
    preheader: `${code} is your Cosmic Fit login code. It expires in 10 minutes.`,
  });
}

// Re-exported so callers can reach brand metadata (e.g. for plain-text fallbacks).
export { brand };
