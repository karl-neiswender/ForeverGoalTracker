// Forever Goal Tracker feedback: emails each new response of the Google Form
// to the form's owner, so reports can be read (and checked by Claude) in Gmail.
//
// Lives in the form's own Apps Script project (form editor > three-dot menu >
// Apps Script). This file is the copy kept with the addon; paste it over the
// project's Code.gs, then run installTrigger once and approve the permissions.
//
// Every email's subject starts with "Forever Goal Tracker feedback", which is
// what the Gmail search for new reports looks for.

var SUBJECT = "Forever Goal Tracker feedback";

// Run once. Running it again replaces the trigger instead of adding a second one.
function installTrigger() {
  var form = FormApp.getActiveForm();
  ScriptApp.getProjectTriggers().forEach(function (t) {
    if (t.getHandlerFunction() === "sendFeedbackEmail") ScriptApp.deleteTrigger(t);
  });
  ScriptApp.newTrigger("sendFeedbackEmail").forForm(form).onFormSubmit().create();
}

function sendFeedbackEmail(e) {
  var answers = {};
  e.response.getItemResponses().forEach(function (r) {
    answers[r.getItem().getTitle()] = String(r.getResponse());
  });
  var kind = answers["What kind of feedback is this?"] || "Feedback";
  var what = answers["What happened, or what would you like?"] || "";
  var details = answers["Details from the addon"] || "(none: sent without the addon)";

  var summary = what.replace(/\s+/g, " ").trim();
  if (summary.length > 70) summary = summary.slice(0, 67) + "...";

  var body = [
    "Kind: " + kind,
    "Sent: " + e.response.getTimestamp(),
    "",
    "What happened, or what they'd like:",
    what,
    "",
    "Details from the addon:",
    details,
  ].join("\n");

  MailApp.sendEmail({
    to: Session.getEffectiveUser().getEmail(),
    subject: SUBJECT + ": " + kind + ": " + summary,
    body: body,
    name: SUBJECT,
  });
}
