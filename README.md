<br/><br/>
<div>
    <h3 align="center">🤖 URL Sentry</h3>
    <p align="center">
        Monitor your clipboard for URLs containing known tracking parameters.
    </p>
</div>
<br><br>

This tool for MacOS monitors your clipboard, scanning for URLs, then removes any known tracking parameters.

### Why Swift?

The clipboard is a pretty sensitive tool. I'm pretty conscious about taking on risk when using third-party libraries. I wanted to keep dependencies at a minimum, and Swift only required depending on Cocoa, Apple's own native API. Similarly, I would probably use PowerShell for a Windows native API.

### Usage

Clone the repo, compile and run:
```sh
cd urlsentry
swiftc URLSentry.swift
./URLSentry
```

Alternatively, you can run it in a tmux session or create a daemon for persistence.

### License

[MIT](https://github.com/williamfedele/urlsentry/blob/main/LICENSE)
