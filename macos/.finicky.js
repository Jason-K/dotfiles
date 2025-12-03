// ~/.finicky.js
export default {
  defaultBrowser: "company.thebrowser.dia",
  options: {
    // Check for updates. Default: true
    checkForUpdates: true,
    // Log every request to file. Default: false
    logRequests: false,
    // Keep Finicky running in the background
    keepRunning: false,
    // Hide the Finicky icon from the menu bar
    hideIcon: false,
  },
  rewrite: [
    {
      // Redirect all x.com urls to use xcancel.com
      match: "x.com/*",
      url: (url) => {
        url.host = "xcancel.com";
        return url;
      },
    },
    {
      match: ({ url }) => url.protocol === "http",
      url: (url) => {
        url.protocol = "https";
        return url;
      },
    },
    {
      match: () => true,
      url: (url) => {
        const removeKeysStartingWith = ["utm_", "uta_"];
        const removeKeys = ["fbclid", "gclid"];

        for (const key of [...url.searchParams.keys()]) {
          if (
            removeKeysStartingWith.some((prefix) => key.startsWith(prefix)) ||
            removeKeys.includes(key)
          ) {
            url.searchParams.delete(key);
          }
        }

        return url.href;
      },
    },
    {
      match: finicky.matchDomains(["google.com"]),
      url: "https://duckduckgo.com",
    },
    {
      // Redirect Tiktok video links to use Proxitok public proxies
      match: ({ url }) =>
        (url.host.endsWith("tiktok.com") && url.pathname.startsWith("/@")) ||
        url.host.endsWith("vm.tiktok.com"),
      url: ({ url }) => {
        // See more https://github.com/pablouser1/ProxiTok/wiki/Public-instances
        const selectRandomTikTokProxy = () => {
          const TIKTOK_PROXIES = [
            "proxitok.pabloferreiro.es", // Official
            "proxitok.pussthecat.org",
            "tok.habedieeh.re",
            "proxitok.esmailelbob.xyz",
            "proxitok.privacydev.net",
            "tok.artemislena.eu",
            "tok.adminforge.de",
            "tt.vern.cc",
            "cringe.whatever.social",
            "proxitok.lunar.icu",
            "proxitok.privacy.com.de",
            "cringe.seitan-ayoub.lol",
            "cringe.datura.network",
            "tt.opnxng.com",
            "tiktok.wpme.pl",
            "proxitok.r4fo.com",
            "proxitok.belloworld.it",
          ];
          return TIKTOK_PROXIES[
            Math.floor(Math.random() * TIKTOK_PROXIES.length)
          ];
        };
        return {
          protocol: "https",
          host: selectRandomTikTokProxy(),
          // Prepend pathname with /@placeholder/video to match ProkiTok urls
          pathname: url.pathname.startsWith("/@")
            ? url.pathname
            : `/@placeholder/video${url.pathname}`,
        };
      },
    },
  ],
  handlers: [
    {
      // Open any link clicked in Mail & Outlook in Google Chrome
      match: (_url, { opener }) =>
        ["com.apple.mail", "com.microsoft.Outlook"].includes(
          opener?.bundleId ?? ""
        ),
      browser: "company.thebrowser.dia",
    },
    {
      // Open google.com and *.google.com urls in Google Chrome
      match: [
        "google.com/*", // match google.com urls
        "*.google.com*", // also match google.com subdomains
      ],
      browser: "company.thebrowser.dia",
    },
    {
      match: finicky.matchDomains("open.spotify.com"),
      browser: "Spotify",
    },
    {
      match: finicky.matchHostnames(["teams.microsoft.com"]),
      browser: "com.microsoft.teams",
      url: ({ url }) => ({ ...url, protocol: "msteams" }),
    },
  ],
};
