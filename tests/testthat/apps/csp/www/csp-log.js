// Record each Content-Security-Policy violation, for test-app-csp.R. This
// file is served from the app itself, so the policy lets it run.
window.cspViolations = [];
document.addEventListener("securitypolicyviolation", function (e) {
  var t = e.target;
  window.cspViolations.push({
    directive: e.violatedDirective,
    sample: e.sample,
    source: e.sourceFile,
    element: t && t.nodeType === 1 ? t.tagName + "." + t.className : String(t)
  });
});
