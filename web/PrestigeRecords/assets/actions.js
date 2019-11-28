var requestUri = { "bhopeasy": true, "bhophard": true, "surfmain": true };
function getParameterByName(name)
{
	var url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"), results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

function performRequest(server, anchor, postload)
{
	var noreload = postload && typeof postload == "function";
	var add = "";
	if (!anchor)
		$("body").addClass("fetching");
	else
		add = "&anchor=" + anchor;
	
	if (!noreload)
	{
		$("<div class=\"loading\">Loading&#8230;</div>").appendTo("body");
		$(".holder").addClass("fetching");
	}
	
	$.get("fetch.php?server=" + server + add, function(data)
	{
		if (!anchor)
		{
			$("body").html(data);
			$("body").removeClass("fetching");
			
			if (postload && postload.substring(0,1) != "!")
				performRequest(server, postload);
		}
		else
		{
			if (noreload)
			{
				postload(data);
			}
			else
			{
				$(".content").html(data);
				
				if (anchor.substring(0,7) != "records" && $(".cmap").attr("orig"))
				{
					$(".cmap").html($(".cmap").attr("orig"));
					$(".cmap").removeAttr("orig");
				}
			}
		}
		
		$(".loading").remove();
		$(".holder").removeClass("fetching");
	});
}

function resolveSteamIds(cont)
{
	var list = [];
	cont.each(function(){
		list.push($(this).attr("data-steam"));
	});
	
	$.get("fetch.php?resolve=" + list.join(), function(data)
	{
		var json = JSON.parse(data);
		if (json.response && json.response.players)
		{
			$.each(json.response.players, function(k,player) {
				cont.each(function(){
					if ($(this).attr("data-steam") == player.steamid){
						$(this).html("<a href=" + player.profileurl + " target=\"_blank\">" + player.personaname + "</a>");
						$(this).removeAttr("data-steam");
						$(this).removeClass("resolve");
					}
				});
			});
		}
	});
}

function navigateBack()
{
	if ($("body").find(".overview")[0])
		window.location.href = './';
	else
	{
		var server = getParameterByName("server");
		if (requestUri[server])
		{
			if (window.location.hash.substring(1).indexOf("!") > 0)
			{
				var split = window.location.hash.substring(1).split("!");
				if (split.length > 1)
					window.location.hash = '#' + split[0];
			}
			else
			{
				window.location.hash = '#!';
				performRequest(server, "home");
			}
		}
	}
}

$(document).ready(function() {
	var server = getParameterByName("server");
	if (requestUri[server])
	{
		performRequest(server, null, window.location.hash != "" ? window.location.hash.substring(1) : null);
		
		$(window).on("hashchange", function(e) {
			var se = getParameterByName("server");
			var hash = window.location.hash.substring(1);
			if (!requestUri[se] || hash.substring(0,1) == "!")
				return;
			
			performRequest(se, hash);
		});
	}
	else
	{
		$(".viewport").mouseenter(function(e) {
			$(this).children("a").children("img").animate({ height: '202', left: '0', top: '0', width: '359'}, 100);
			$(this).children("a").children("span").fadeIn(200);
		}).mouseleave(function(e) {
			$(this).children("a").children("img").animate({ height: '225', left: '-20', top: '-20', width: '400'}, 100);
			$(this).children("a").children("span").fadeOut(200);
		});
		
		$("body").removeClass("fetching");
	}
});