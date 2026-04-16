export function renderOtpEmail(code: string, email: string): string {
  const deepLink = `cosmicfit://login?code=${encodeURIComponent(code)}&email=${encodeURIComponent(email)}`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Your login code</title>
</head>
<body style="margin:0; padding:0; background-color:#1C1C2E; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#1C1C2E;">
    <tr>
      <td align="center" style="padding:40px 16px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:440px; background-color:#2A2A3D; border-radius:16px; box-shadow:0 2px 12px rgba(0,0,0,0.3);">

          <!-- Logo -->
          <tr>
            <td align="center" style="padding:36px 32px 8px;">
              <div style="font-size:44px; line-height:1;">&#10024;</div>
              <p style="margin:8px 0 0; font-size:15px; font-weight:600; color:#7E69E6;">
                Cosmic Fit
              </p>
            </td>
          </tr>

          <!-- THE CODE -->
          <tr>
            <td align="center" style="padding:16px 32px 8px;">
              <p style="margin:0 0 20px; font-size:15px; line-height:1.5; color:#DEDEDE;">
                Your login code is
              </p>
              <div style="display:inline-block; padding:20px 48px; background-color:#1C1C2E; border-radius:16px; border:2px dashed #7E69E6;">
                <span style="font-size:42px; font-weight:800; letter-spacing:10px; color:#7E69E6; font-family:'Menlo','Courier New',monospace;">
                  ${code}
                </span>
              </div>
              <p style="margin:20px 0 0; font-size:14px; line-height:1.5; color:#DEDEDE;">
                Enter this code in the app to sign in.
              </p>
            </td>
          </tr>

          <!-- Deep-link button -->
          <tr>
            <td align="center" style="padding:24px 32px 8px;">
              <a href="${deepLink}" target="_blank"
                 style="display:inline-block; padding:14px 36px; background-color:#7E69E6; color:#FFFFFF; font-size:16px; font-weight:600; text-decoration:none; border-radius:12px;">
                Open Cosmic Fit
              </a>
              <p style="margin:10px 0 0; font-size:12px; color:#888888;">
                Or enter the code manually in the app.
              </p>
            </td>
          </tr>

          <!-- Expiry -->
          <tr>
            <td align="center" style="padding:16px 32px 0;">
              <p style="margin:0; font-size:13px; line-height:1.5; color:#888888;">
                This code expires in 10 minutes.<br />
                If you didn't request this, you can safely ignore it.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:24px 32px 32px;">
              <div style="border-top:1px solid #3A3A4D; padding-top:16px;">
                <p style="margin:0; font-size:12px; color:#666666;">
                  Cosmic Fit &mdash; Your style, written in the stars.
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
