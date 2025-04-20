<!-- Statistics -->
```
Video count: 892
Date range: 2018-03-26 -> 2025-04-13
Message count: 3,661,481
```

On May 19, 2025 Twitch will implement a 100-hour storage limit for [highlights](https://help.twitch.tv/s/article/video-on-demand#highlights) and [uploads](https://help.twitch.tv/s/article/video-on-demand#uploads). Channels still over the limit by the deadline will have their content deleted until they have been brought under the 100-hour limit, along with their chat replays.

This repository aims to preserve [the greatest corner of the internet](https://www.twitch.tv/popout/greatsphynx/chat).

Uses [TwitchDownloader](https://github.com/lay295/TwitchDownloader)'s [CLI](https://github.com/lay295/TwitchDownloader/blob/master/TwitchDownloaderCLI/README.md) for downloading chat data as JSON and converting it to HTML, which is then [processed](/src/scripts/Optimize-HTML.ps1) to significantly reduce file sizes.

The downloaded JSON can be used to [render the chat as a video](https://github.com/lay295/TwitchDownloader/blob/master/TwitchDownloaderCLI/README.md#arguments-for-mode-chatrender) and is available [on archive.org](https://archive.org/details/greatsphynx-chat-archive-json).

<p align='center'>
	<picture>
		<a href='https://www.twitch.tv/popout/greatsphynx/chat'>
			<img src='https://static-cdn.jtvnw.net/emoticons/v2/emotesv2_1c09fae8d05043bc98f007b22b0ceb4d/default/dark/1.0'>
		</a>
	</picture>
	<picture>
		<a href='https://www.twitch.tv/popout/greatsphynx/chat'>
			<img src='https://cdn.7tv.app/emote/01JNJJT230T9MPBCPAMEY9CYRP/1x.webp'>
		</a>
	</picture>
	<picture>
		<a href='https://www.twitch.tv/popout/greatsphynx/chat'>
			<img src='https://cdn.betterttv.net/emote/665e3c1ee47776776a3b4fe3/1x'>
		</a>
	</picture>
	<picture>
		<a href='https://www.twitch.tv/popout/greatsphynx/chat'>
			<img src='https://cdn.betterttv.net/emote/5fdc7773a926f43485cebbf3/1x'>
		</a>
	</picture>
	<picture>
		<a href='https://www.twitch.tv/popout/greatsphynx/chat'>
			<img src='https://cdn.betterttv.net/emote/5e9f54fdce7cbf62fe15713a/1x'>
		</a>
	</picture>
</p>
