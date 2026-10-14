// Open links in a new tab: every link in the page content (except same-page anchors)
// and every external link anywhere on the page (header repo link, footer social icons).
// Site navigation (menu, previous/next) stays in the same tab.
document.addEventListener(
  "click",
  function (event) {
    var link = event.target.closest("a[href]");
    if (!link) return;
    var href = link.getAttribute("href");
    if (href.startsWith("#")) return;
    var external = link.host !== window.location.host;
    if (external || link.closest(".md-content")) {
      link.setAttribute("target", "_blank");
      link.setAttribute("rel", "noopener");
    }
  },
  true
);
