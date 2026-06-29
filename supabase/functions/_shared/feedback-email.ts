import {
  brand,
  divider,
  heading,
  paragraph,
  fineprint,
  renderEmail,
} from "./email-theme.ts";

interface FeedbackEmailParams {
  message: string;
  userEmail: string | null;
  userId: string;
  displayDate: string | null;
  deviceModel: string | null;
  iosVersion: string | null;
  appVersion: string | null;
}

function metadataRow(label: string, value: string): string {
  return `<tr>
    <td style="padding:4px 12px 4px 0; font-family:${brand.fonts.sans}; font-size:13px; color:${brand.colors.inkFaint}; white-space:nowrap; vertical-align:top;">${label}</td>
    <td style="padding:4px 0; font-family:${brand.fonts.sans}; font-size:13px; color:${brand.colors.ink}; word-break:break-all;">${value}</td>
  </tr>`;
}

export function renderFeedbackEmail(params: FeedbackEmailParams): string {
  const rows: string[] = [];
  if (params.userEmail) rows.push(metadataRow("From", params.userEmail));
  rows.push(metadataRow("User ID", params.userId));
  if (params.displayDate) rows.push(metadataRow("Daily Fit Date", params.displayDate));
  if (params.deviceModel) rows.push(metadataRow("Device", params.deviceModel));
  if (params.iosVersion) rows.push(metadataRow("iOS", params.iosVersion));
  if (params.appVersion) rows.push(metadataRow("App Version", params.appVersion));

  const metadataTable = `<table role="presentation" cellpadding="0" cellspacing="0" style="margin-top:8px; width:100%;">${rows.join("")}</table>`;

  const content = `
    ${heading("New Feedback")}
    ${paragraph(params.message)}
    ${divider()}
    <div style="margin-top:12px;">
      ${fineprint("Sender details")}
      ${metadataTable}
    </div>
  `;

  const subject = params.displayDate
    ? `Cosmic Fit Feedback \u2014 ${params.displayDate}`
    : "Cosmic Fit Feedback \u2014 Daily Fit";

  return renderEmail({
    content,
    title: subject,
    preheader: params.message.slice(0, 100),
    centered: false,
  });
}
