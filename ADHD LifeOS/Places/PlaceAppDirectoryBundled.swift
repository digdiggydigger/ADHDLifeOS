//
//  PlaceAppDirectoryBundled.swift
//  ADHD LifeOS
//
//  The shipped base of the app directory (F-AppDirectory-1-Directory). A Swift constant, not a
//  bundle resource — there is no load step to fail, and the sweep test walks the real list.
//
//  THE CURATION RULE, which outranks list size: every scheme here is checked against published
//  documentation or the well-established scheme collections — a wrong scheme teaches E the
//  whole feature lies. Apps whose scheme could not be confirmed are OMITTED, not guessed
//  (checked and left out 2026-09-01: Google Calendar, Dropbox, Cash App, Fantastical, Prime
//  Video, Max). They stay reachable through block 2's pasted share-links, and block 4's remote
//  top-up can add them later without a release.
//
//  Ranks are the directory's own sense of "the apps most people mean": 90s for the giants,
//  0–20 for the long tail. Higher lists first within a search tier.
//

import Foundation

enum PlaceAppDirectoryBundled {
    static let entries: [PlaceAppDirectoryEntry] = apple + google + social + streaming
        + productivity + reading + travel + health + money + utilities

    // MARK: - Apple built-ins

    private static let apple: [PlaceAppDirectoryEntry] = [
        .init(scheme: "music", name: "Apple Music", keywords: ["songs", "playlist", "listen"],
              universalLinkHosts: ["music.apple.com"], rank: 85),
        .init(scheme: "maps", name: "Apple Maps", keywords: ["directions", "navigation", "route"],
              universalLinkHosts: ["maps.apple.com"],
              destinations: [.init(name: "Directions to an address", template: "maps://?daddr={value}")],
              rank: 90),
        .init(scheme: "videos", name: "Apple TV", keywords: ["tv", "movies", "streaming"], rank: 40),
        .init(scheme: "itms-apps", name: "App Store", keywords: ["apps", "download", "updates"], rank: 60),
        .init(scheme: "ibooks", name: "Books", keywords: ["reading", "ebooks", "audiobooks"], rank: 45),
        .init(scheme: "calshow", name: "Calendar", keywords: ["events", "schedule", "appointments"], rank: 70),
        .init(scheme: "camera", name: "Camera", keywords: ["photo", "video", "picture"], rank: 55),
        .init(scheme: "facetime", name: "FaceTime", keywords: ["call", "video call"], rank: 60),
        .init(scheme: "shareddocuments", name: "Files", keywords: ["documents", "folders", "downloads"], rank: 50),
        .init(scheme: "findmy", name: "Find My", keywords: ["locate", "devices", "friends"], rank: 45),
        .init(scheme: "fitnessapp", name: "Fitness", keywords: ["workout", "rings", "activity"], rank: 55),
        .init(scheme: "x-apple-health", name: "Health", keywords: ["medical", "sleep", "steps"], rank: 55),
        .init(scheme: "message", name: "Mail", keywords: ["email", "inbox"], rank: 75),
        .init(scheme: "mobilenotes", name: "Notes", keywords: ["writing", "checklist"], rank: 70),
        .init(scheme: "photos-redirect", name: "Photos", keywords: ["pictures", "library", "albums"], rank: 75),
        .init(scheme: "podcasts", name: "Podcasts", keywords: ["listen", "shows", "episodes"], rank: 60),
        .init(scheme: "x-apple-reminderkit", name: "Reminders", keywords: ["tasks", "todo", "lists"], rank: 60),
        .init(scheme: "shortcuts", name: "Shortcuts", keywords: ["automation", "workflows"], rank: 55),
        .init(scheme: "stocks", name: "Stocks", keywords: ["shares", "market", "investing"], rank: 30),
        .init(scheme: "voicememos", name: "Voice Memos", keywords: ["recording", "audio", "dictate"], rank: 40),
        .init(scheme: "shoebox", name: "Wallet", keywords: ["cards", "passes", "tickets", "pay"], rank: 55),
        .init(scheme: "weather", name: "Weather", keywords: ["forecast", "rain", "temperature"], rank: 55)
    ]

    // MARK: - Google

    private static let google: [PlaceAppDirectoryEntry] = [
        .init(scheme: "googlechrome", name: "Chrome", keywords: ["browser", "web", "google"], rank: 70),
        .init(scheme: "googlegmail", name: "Gmail", keywords: ["email", "inbox", "google"], rank: 85),
        .init(scheme: "googledocs", name: "Google Docs", keywords: ["documents", "writing"], rank: 50),
        .init(scheme: "googledrive", name: "Google Drive", keywords: ["files", "storage", "cloud"], rank: 65),
        .init(scheme: "comgooglemaps", name: "Google Maps",
              keywords: ["directions", "navigation", "route", "traffic"],
              universalLinkHosts: ["maps.app.goo.gl", "maps.google.com"],
              destinations: [
                .init(name: "Directions to an address", template: "comgooglemaps://?daddr={value}")
              ],
              rank: 95),
        .init(scheme: "googlephotos", name: "Google Photos", keywords: ["pictures", "backup"], rank: 60),
        .init(scheme: "googlesheets", name: "Google Sheets", keywords: ["spreadsheet"], rank: 45),
        .init(scheme: "googletranslate", name: "Google Translate", keywords: ["language", "translate"], rank: 45),
        .init(scheme: "waze", name: "Waze", keywords: ["navigation", "traffic", "driving"], rank: 60),
        .init(scheme: "youtube", name: "YouTube", keywords: ["video", "watch", "streaming"],
              universalLinkHosts: ["youtube.com", "www.youtube.com", "youtu.be", "m.youtube.com"],
              destinations: [
                .init(name: "A video", template: "https://www.youtube.com/watch?v={value}")
              ],
              rank: 95),
        .init(scheme: "youtubemusic", name: "YouTube Music", keywords: ["songs", "playlist"], rank: 55)
    ]

    // MARK: - Social & messaging

    private static let social: [PlaceAppDirectoryEntry] = [
        .init(scheme: "bereal", name: "BeReal", keywords: ["photo", "friends"], rank: 25),
        .init(scheme: "discord", name: "Discord", keywords: ["chat", "servers", "gaming"],
              universalLinkHosts: ["discord.com", "discord.gg"], rank: 70),
        .init(scheme: "fb", name: "Facebook", keywords: ["social", "friends", "feed"],
              universalLinkHosts: ["facebook.com", "www.facebook.com"], rank: 80),
        .init(scheme: "instagram", name: "Instagram", keywords: ["photo", "stories", "reels", "social"],
              universalLinkHosts: ["instagram.com", "www.instagram.com"],
              destinations: [.init(name: "A profile", template: "instagram://user?username={value}")],
              rank: 90),
        .init(scheme: "kakaotalk", name: "KakaoTalk", keywords: ["chat", "messaging"], rank: 15),
        .init(scheme: "line", name: "LINE", keywords: ["chat", "messaging"], rank: 20),
        .init(scheme: "linkedin", name: "LinkedIn", keywords: ["work", "jobs", "network"],
              universalLinkHosts: ["linkedin.com", "www.linkedin.com"], rank: 60),
        .init(scheme: "fb-messenger", name: "Messenger", keywords: ["chat", "facebook"], rank: 70),
        .init(scheme: "msteams", name: "Microsoft Teams", keywords: ["work", "meetings", "chat"], rank: 55),
        .init(scheme: "pinterest", name: "Pinterest", keywords: ["ideas", "boards", "inspiration"],
              universalLinkHosts: ["pinterest.com", "www.pinterest.com", "pin.it"], rank: 55),
        .init(scheme: "reddit", name: "Reddit", keywords: ["forum", "communities", "news"],
              universalLinkHosts: ["reddit.com", "www.reddit.com"], rank: 70),
        .init(scheme: "sgnl", name: "Signal", keywords: ["messaging", "private", "chat"], rank: 55),
        .init(scheme: "slack", name: "Slack", keywords: ["work", "chat", "channels"], rank: 65),
        .init(scheme: "snapchat", name: "Snapchat", keywords: ["photo", "chat", "stories"], rank: 65),
        .init(scheme: "tg", name: "Telegram", keywords: ["chat", "messaging", "channels"],
              universalLinkHosts: ["t.me"],
              destinations: [.init(name: "Chat with a username", template: "tg://resolve?domain={value}")],
              rank: 65),
        .init(scheme: "barcelona", name: "Threads", keywords: ["social", "posts", "meta"],
              universalLinkHosts: ["threads.net", "www.threads.net", "threads.com", "www.threads.com"],
              rank: 45),
        .init(scheme: "tiktok", name: "TikTok", keywords: ["video", "social", "fyp"],
              universalLinkHosts: ["tiktok.com", "www.tiktok.com", "vm.tiktok.com"], rank: 85),
        .init(scheme: "tumblr", name: "Tumblr", keywords: ["blog", "social"], rank: 30),
        .init(scheme: "viber", name: "Viber", keywords: ["chat", "calls"], rank: 15),
        .init(scheme: "weixin", name: "WeChat", keywords: ["chat", "messaging"], rank: 30),
        .init(scheme: "whatsapp", name: "WhatsApp", keywords: ["chat", "messaging", "calls"],
              universalLinkHosts: ["wa.me", "api.whatsapp.com"],
              destinations: [
                .init(name: "Chat with a phone number", template: "whatsapp://send?phone={value}")
              ],
              rank: 95),
        .init(scheme: "twitter", name: "X (Twitter)", keywords: ["tweets", "posts", "news", "social"],
              universalLinkHosts: ["twitter.com", "x.com"],
              destinations: [.init(name: "A profile", template: "twitter://user?screen_name={value}")],
              rank: 80),
        .init(scheme: "zoomus", name: "Zoom", keywords: ["meetings", "video call", "work"], rank: 60)
    ]

    // MARK: - Streaming, video & audio

    private static let streaming: [PlaceAppDirectoryEntry] = [
        .init(scheme: "audible", name: "Audible", keywords: ["audiobooks", "listen"], rank: 50),
        .init(scheme: "deezer", name: "Deezer", keywords: ["music", "streaming"], rank: 25),
        .init(scheme: "disneyplus", name: "Disney+", keywords: ["movies", "tv", "streaming"], rank: 60),
        .init(scheme: "hulu", name: "Hulu", keywords: ["tv", "streaming"], rank: 50),
        .init(scheme: "imdb", name: "IMDb", keywords: ["movies", "tv", "ratings"],
              universalLinkHosts: ["imdb.com", "www.imdb.com", "m.imdb.com"], rank: 45),
        .init(scheme: "letterboxd", name: "Letterboxd", keywords: ["movies", "film", "reviews"],
              universalLinkHosts: ["letterboxd.com", "boxd.it"], rank: 35),
        .init(scheme: "nflx", name: "Netflix", keywords: ["movies", "tv", "streaming"],
              universalLinkHosts: ["netflix.com", "www.netflix.com"], rank: 85),
        .init(scheme: "overcast", name: "Overcast", keywords: ["podcasts", "listen"],
              universalLinkHosts: ["overcast.fm"], rank: 35),
        .init(scheme: "pandora", name: "Pandora", keywords: ["music", "radio"], rank: 40),
        .init(scheme: "plex", name: "Plex", keywords: ["media", "movies", "server"], rank: 30),
        .init(scheme: "pktc", name: "Pocket Casts", keywords: ["podcasts", "listen"], rank: 35),
        .init(scheme: "shazam", name: "Shazam", keywords: ["music", "identify", "song"], rank: 45),
        .init(scheme: "soundcloud", name: "SoundCloud", keywords: ["music", "tracks", "artists"],
              universalLinkHosts: ["soundcloud.com", "on.soundcloud.com"], rank: 50),
        .init(scheme: "spotify", name: "Spotify", keywords: ["music", "playlist", "podcast", "listen"],
              universalLinkHosts: ["open.spotify.com", "spotify.link"],
              destinations: [
                .init(name: "A playlist", template: "https://open.spotify.com/playlist/{value}")
              ],
              rank: 95),
        .init(scheme: "tidal", name: "TIDAL", keywords: ["music", "streaming"], rank: 30),
        .init(scheme: "twitch", name: "Twitch", keywords: ["streaming", "gaming", "live"],
              universalLinkHosts: ["twitch.tv", "www.twitch.tv", "m.twitch.tv"], rank: 60),
        .init(scheme: "vlc", name: "VLC", keywords: ["video", "player", "media"], rank: 30)
    ]

    // MARK: - Productivity & work

    private static let productivity: [PlaceAppDirectoryEntry] = [
        .init(scheme: "onepassword", name: "1Password", keywords: ["passwords", "vault"], rank: 40),
        .init(scheme: "anki", name: "AnkiMobile", keywords: ["flashcards", "study", "revision"], rank: 30),
        .init(scheme: "asana", name: "Asana", keywords: ["work", "projects", "tasks"], rank: 40),
        .init(scheme: "bear", name: "Bear", keywords: ["notes", "writing", "markdown"], rank: 35),
        .init(scheme: "bitwarden", name: "Bitwarden", keywords: ["passwords", "vault"], rank: 35),
        .init(scheme: "canva", name: "Canva", keywords: ["design", "graphics"], rank: 45),
        .init(scheme: "chatgpt", name: "ChatGPT", keywords: ["ai", "assistant", "openai"],
              universalLinkHosts: ["chatgpt.com"], rank: 75),
        .init(scheme: "claude", name: "Claude", keywords: ["ai", "assistant", "anthropic"],
              universalLinkHosts: ["claude.ai"], rank: 70),
        .init(scheme: "craftdocs", name: "Craft", keywords: ["notes", "documents"], rank: 25),
        .init(scheme: "dayone", name: "Day One", keywords: ["journal", "diary", "writing"], rank: 40),
        .init(scheme: "drafts", name: "Drafts", keywords: ["notes", "capture", "writing"], rank: 30),
        .init(scheme: "evernote", name: "Evernote", keywords: ["notes", "notebooks"], rank: 40),
        .init(scheme: "figma", name: "Figma", keywords: ["design", "prototype", "work"], rank: 45),
        .init(scheme: "forestapp", name: "Forest", keywords: ["focus", "timer", "trees"], rank: 30),
        .init(scheme: "github", name: "GitHub", keywords: ["code", "repos", "work"],
              universalLinkHosts: ["github.com"], rank: 50),
        .init(scheme: "linear", name: "Linear", keywords: ["issues", "work", "projects"], rank: 35),
        .init(scheme: "ms-excel", name: "Microsoft Excel", keywords: ["spreadsheet", "work"], rank: 45),
        .init(scheme: "ms-outlook", name: "Microsoft Outlook", keywords: ["email", "work", "calendar"], rank: 60),
        .init(scheme: "ms-powerpoint", name: "Microsoft PowerPoint", keywords: ["slides", "work"], rank: 40),
        .init(scheme: "ms-word", name: "Microsoft Word", keywords: ["documents", "writing", "work"], rank: 50),
        .init(scheme: "notion", name: "Notion", keywords: ["notes", "wiki", "databases", "work"],
              universalLinkHosts: ["notion.so", "www.notion.so"], rank: 65),
        .init(scheme: "obsidian", name: "Obsidian", keywords: ["notes", "markdown", "vault"], rank: 45),
        .init(scheme: "omnifocus", name: "OmniFocus", keywords: ["tasks", "gtd", "projects"], rank: 30),
        .init(scheme: "onenote", name: "OneNote", keywords: ["notes", "notebooks"], rank: 45),
        .init(scheme: "perplexity", name: "Perplexity", keywords: ["ai", "search", "answers"], rank: 40),
        .init(scheme: "streaks", name: "Streaks", keywords: ["habits", "goals"], rank: 25),
        .init(scheme: "things", name: "Things", keywords: ["tasks", "todo", "projects"], rank: 40),
        .init(scheme: "ticktick", name: "TickTick", keywords: ["tasks", "todo", "habits"], rank: 35),
        .init(scheme: "todoist", name: "Todoist", keywords: ["tasks", "todo", "projects"], rank: 45),
        .init(scheme: "trello", name: "Trello", keywords: ["boards", "kanban", "work"], rank: 40)
    ]

    // MARK: - Reading & news

    private static let reading: [PlaceAppDirectoryEntry] = [
        .init(scheme: "applenews", name: "Apple News", keywords: ["headlines", "articles"], rank: 55),
        .init(scheme: "bbcnews", name: "BBC News", keywords: ["headlines", "uk", "world"], rank: 55),
        .init(scheme: "feedly", name: "Feedly", keywords: ["rss", "articles"], rank: 30),
        .init(scheme: "flipboard", name: "Flipboard", keywords: ["magazine", "articles"], rank: 30),
        .init(scheme: "goodreads", name: "Goodreads", keywords: ["books", "reading", "reviews"],
              universalLinkHosts: ["goodreads.com", "www.goodreads.com"], rank: 40),
        .init(scheme: "gnmguardian", name: "The Guardian", keywords: ["news", "uk"], rank: 45),
        .init(scheme: "instapaper", name: "Instapaper", keywords: ["read later", "articles"], rank: 25),
        .init(scheme: "kindle", name: "Kindle", keywords: ["books", "reading", "ebooks"], rank: 55),
        .init(scheme: "medium", name: "Medium", keywords: ["articles", "blogs"],
              universalLinkHosts: ["medium.com"], rank: 35),
        .init(scheme: "nytimes", name: "The New York Times", keywords: ["news", "articles"], rank: 45),
        .init(scheme: "substack", name: "Substack", keywords: ["newsletters", "writers"],
              universalLinkHosts: ["substack.com"], rank: 35),
        .init(scheme: "wikipedia", name: "Wikipedia", keywords: ["encyclopedia", "reference"],
              universalLinkHosts: ["wikipedia.org", "en.wikipedia.org", "en.m.wikipedia.org"], rank: 50)
    ]

    // MARK: - Travel, transport & food

    private static let travel: [PlaceAppDirectoryEntry] = [
        .init(scheme: "airbnb", name: "Airbnb", keywords: ["stays", "travel", "holiday"],
              universalLinkHosts: ["airbnb.com", "www.airbnb.com", "airbnb.co.uk", "www.airbnb.co.uk"],
              rank: 55),
        .init(scheme: "alltrails", name: "AllTrails", keywords: ["hiking", "walks", "trails"],
              universalLinkHosts: ["alltrails.com", "www.alltrails.com"], rank: 40),
        .init(scheme: "booking", name: "Booking.com", keywords: ["hotels", "travel", "stays"], rank: 50),
        .init(scheme: "citymapper", name: "Citymapper", keywords: ["transit", "bus", "train", "tube"], rank: 60),
        .init(scheme: "deliveroo", name: "Deliveroo", keywords: ["food", "delivery", "takeaway"], rank: 55),
        .init(scheme: "doordash", name: "DoorDash", keywords: ["food", "delivery"], rank: 45),
        .init(scheme: "komoot", name: "Komoot", keywords: ["cycling", "hiking", "routes"], rank: 30),
        .init(scheme: "lyft", name: "Lyft", keywords: ["ride", "taxi"], rank: 50),
        .init(scheme: "skyscanner", name: "Skyscanner", keywords: ["flights", "travel"], rank: 40),
        .init(scheme: "starbucks", name: "Starbucks", keywords: ["coffee", "order"], rank: 40),
        .init(scheme: "trainline", name: "Trainline", keywords: ["trains", "tickets", "rail"], rank: 50),
        .init(scheme: "tripadvisor", name: "Tripadvisor", keywords: ["travel", "restaurants", "reviews"],
              rank: 40),
        .init(scheme: "uber", name: "Uber", keywords: ["ride", "taxi", "car"], rank: 75),
        .init(scheme: "ubereats", name: "Uber Eats", keywords: ["food", "delivery", "takeaway"], rank: 55)
    ]

    // MARK: - Health & fitness

    private static let health: [PlaceAppDirectoryEntry] = [
        .init(scheme: "calm", name: "Calm", keywords: ["meditation", "sleep", "relax"], rank: 40),
        .init(scheme: "fitbit", name: "Fitbit", keywords: ["steps", "activity", "sleep"], rank: 35),
        .init(scheme: "headspace", name: "Headspace", keywords: ["meditation", "mindfulness"], rank: 40),
        .init(scheme: "mfp", name: "MyFitnessPal", keywords: ["calories", "food", "diet"], rank: 40),
        .init(scheme: "strava", name: "Strava", keywords: ["running", "cycling", "workout"],
              universalLinkHosts: ["strava.com", "www.strava.com"], rank: 55)
    ]

    // MARK: - Money & shopping

    private static let money: [PlaceAppDirectoryEntry] = [
        .init(scheme: "com.amazon.mobile.shopping", name: "Amazon", keywords: ["shopping", "orders", "shop"],
              universalLinkHosts: ["amazon.com", "www.amazon.com", "amazon.co.uk", "www.amazon.co.uk"],
              rank: 75),
        .init(scheme: "coinbase", name: "Coinbase", keywords: ["crypto", "bitcoin"], rank: 30),
        .init(scheme: "depop", name: "Depop", keywords: ["clothes", "secondhand", "selling"], rank: 35),
        .init(scheme: "ebay", name: "eBay", keywords: ["shopping", "auctions", "selling"],
              universalLinkHosts: ["ebay.com", "www.ebay.com", "ebay.co.uk", "www.ebay.co.uk"], rank: 55),
        .init(scheme: "etsy", name: "Etsy", keywords: ["handmade", "shopping", "crafts"], rank: 45),
        .init(scheme: "monzo", name: "Monzo", keywords: ["bank", "money", "card"], rank: 55),
        .init(scheme: "paypal", name: "PayPal", keywords: ["money", "payments"], rank: 55),
        .init(scheme: "revolut", name: "Revolut", keywords: ["bank", "money", "card"], rank: 50),
        .init(scheme: "robinhood", name: "Robinhood", keywords: ["stocks", "investing"], rank: 30),
        .init(scheme: "venmo", name: "Venmo", keywords: ["money", "payments", "split"], rank: 45),
        .init(scheme: "vinted", name: "Vinted", keywords: ["clothes", "secondhand", "selling"], rank: 40)
    ]

    // MARK: - Browsers, learning & utilities

    private static let utilities: [PlaceAppDirectoryEntry] = [
        .init(scheme: "authy", name: "Authy", keywords: ["2fa", "codes", "security"], rank: 25),
        .init(scheme: "brave", name: "Brave", keywords: ["browser", "web"], rank: 35),
        .init(scheme: "duolingo", name: "Duolingo", keywords: ["language", "learning", "practice"], rank: 50),
        .init(scheme: "firefox", name: "Firefox", keywords: ["browser", "web"], rank: 45),
        .init(scheme: "microsoft-edge", name: "Microsoft Edge", keywords: ["browser", "web"], rank: 35),
        .init(scheme: "protonmail", name: "Proton Mail", keywords: ["email", "private"], rank: 35),
        .init(scheme: "roblox", name: "Roblox", keywords: ["games", "play"], rank: 45)
    ]
}
