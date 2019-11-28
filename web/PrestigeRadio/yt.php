<!DOCTYPE html>
<html>
<head>
	<style type="text/css">
	html, body {
		height: 100%;
		margin: 0;
		padding: 0;
		margin-bottom: 0;

		overflow: hidden;
		background-color: black;
		height: calc(100% - 5px);
	}
	#playerdiv, embed {
		width: 100%;
		height: 100%;
	}
	</style>
</head>
<body>
	<div id="playerdiv"></div>

	<script type="text/javascript" src="medialib.js"></script>
	<script type="text/javascript">
		var seeker;
		mcontrol = medialib.createEventDelegate({
			play: function() {
				this.playVideo();
			},
			pause: function() {
				this.pauseVideo();
			},
			seek: function(obj, timeAdded) {
				seeker = {started: timeAdded, target: obj.time, allowInaccurate: obj.allowInaccurate, targetAccuracy: obj.targetAccuracy || 0.2};
			},
			volume: function(obj) {
				this.setVolume(obj.vol);
			}
		});
		
		setInterval(function() {
			if (seeker && mcontrol.loaded) {
				var newTarget = (new Date().getTime() - seeker.started) * 0.001 + seeker.target;
				mcontrol.loadedPlayer.seekTo(newTarget, true);

				var curAccuracy = Math.abs(newTarget - mcontrol.loadedPlayer.getCurrentTime());
				if (seeker.allowInaccurate || curAccuracy < seeker.targetAccuracy) {
					seeker = undefined;
				}
			}
		}, 200);
		
		setInterval(function() {
			if (mcontrol.loaded) {
				var ntime = mcontrol.loadedPlayer.getCurrentTime();
				if (!mcontrol.lastSent || mcontrol.lastSent != ntime) {
					mcontrol.lastSent = ntime;
					medialib.emitEvent("timeChange", {time: ntime});
				}
			}
		}, 500);

		var params = medialib.getParams();
		var id = params.id || params.vid;
		var vol = params.vol || params.volume || 100;
		
		function onYouTubeIframeAPIReady() {
			if (!id)
				return;

			var player = new YT.Player('playerdiv', {
				height: '100%',
				width: '100%',
				videoId: id,
				playerVars: {
					"iv_load_policy": 3
				},
				events: {
					onReady: function(event) {
						event.target.setVolume(vol);
						event.target.playVideo();
						
						mcontrol.playerLoaded(event.target);
					}
				}
			});

			player.youtube = true;
			player.addEventListener("onStateChange", function(event) {
				var state;
				switch(event.data) {
				case 0:
					state = "ended";
					break;
				case 1:
					state = "playing";
					break;
				case 2:
					state = "paused";
					break;
				case 3:
					state = "buffering";
					break;
				case -1:
				default:
					return;
				}
				medialib.emitEvent("stateChange", {state: state, time: player.getCurrentTime()});
			});
			player.addEventListener("onError", function(event) {
				var error;
				switch(event.data) {
				case 2:
					error = "invalid parameter";
					break;
				case 100:
					error = "video not found";
					break;
				case 101:
				case 150:
					error = "embed not allowed";
					break;
				default:
					return;
				}
				medialib.emitEvent("error", {message: error});
			});
		}
		
		medialib.loadAsync("http://www.youtube.com/iframe_api");
	</script>
</body>
</html>