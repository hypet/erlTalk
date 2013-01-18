var ws;
var curContact;
var map = {};

function init(){
	host = "127.0.0.1";
	port = "8088";
	$('#login').html(getCookie("login"));
	if ("WebSocket" in window) {
		window.ws = new WebSocket("ws://" + host + ":" + port + "/service");
	} else if ("MozWebSocket" in window) {
		window.ws = new MozWebSocket("ws://" + host + ":" + port + "/service");
	}
	
	if (window.ws) {
		// browser supports websockets
		window.ws.onopen = function() {
			window.ws.send(getCookie("login") + ":" + getCookie("key") + ":" + getCookie("misultin_session") + ":" + getCookie("hash"));
		};
		window.ws.onmessage = function (evt) {
			var receivedMsg = evt.data;
			onIncomeMsg(receivedMsg);
		};
		window.ws.onclose = function() {
			renderMsg("websocket was closed", "rcvd");
		};
	} else {
		// browser does not support websockets
		// addStatus("sorry, your browser does not support websockets.");
	}
}

function renderHTML(text) { 
    console.log(text);
    var rawText = text;
//    var urlRegex = /(([a-z]+:\/\/)?(([a-z0-9\-]+\.)+([a-z]{2}|aero|arpa|biz|com|coop|edu|gov|info|int|jobs|mil|museum|name|nato|net|org|pro|travel|local|internal))(:[0-9]{1,5})?(\/[a-z0-9_\-\.~]+)*(\/([a-z0-9_\-\.]*)(\?[a-z0-9+_\-\.%=&amp;]*)?)?(#[a-zA-Z0-9!$&'()*+.=-_~:@/?]*)?)(\s+|$)/gi;
    var urlRegex =/(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig;
    var smileyRegex = /\[([-\w\s]+\.\w{3,4})\]/ig;
    rawText = rawText.replace(new RegExp("\n", "g"), "<br/>");
    var result = rawText.replace(urlRegex, function(url) {   
    if ( ( url.indexOf(".jpeg") > 0 ) || ( url.indexOf(".jpg") > 0 ) || ( url.indexOf(".png") > 0 ) || ( url.indexOf(".gif") > 0 ) ) {
        return '<a href="' + url + '">[Link]</a><br/><img src="' + url + '">' + '<br/>'
  } else {
      if (url.indexOf("http") <= 0) {
	url = "http://" + url;
	}
	return '<a href="' + url + '">' + url + '</a>' + '<br/>'
   }
  });
  result = result.replace(smileyRegex, function(url) {   
	return '<span style="display:inline"><img src="/static/' + url.replace('[', '').replace(']', '') + '"></span>';
  });
  return result;
}

function renderMsg(data, msgType, from) {
	console.log("data:" + data);
	var date = new Date();
	return "<div class='msg " + msgType + "'>" + 
        "<div>" +
	"<span class='date'>" + date.toLocaleTimeString() + "</span>" + 
	"<span class='from'>&nbsp;From: " + (from != null ? from : "me") + "</span>" +
        "</div>" +
	renderHTML(data) + "</div>";
}

function getCurrentTarget() {
	return window.curContact.h;
}

function sendMsg(source, target) {
	if (window.ws) {
		console.log("sendMsg");
		var body = $(source).val();
		console.log("body: " + body);
		var to = getCurrentTarget();
		console.log("to: " + to);
		var data = {
			"a" : "msg",
			"p" : {"to" : to, "body" : body}
		};
		console.log(data);
		window.ws.send(JSON.stringify(data));
		var targetDiv = "#l-" + target;
		$(targetDiv).html($(targetDiv).html() + renderMsg($(source).val(), "sent"));
		$(source).val("");
		$(source).focus();
	}
}

function getCookie(key) {
	var i,x,y,ARRcookies = document.cookie.split(";");
	for (i = 0; i < ARRcookies.length; i++)
	{
		x = ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
		y = ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
		x = x.replace(/^\s+|\s+$/g,"");
		if (x == key) {
			return unescape(y);
		}
	}
}

function showSmileyWindow() {
	$.ajax({
		url: "/faces"
	}).done(function(data) {
		var imgs = "";
		for (i = 0; i < data.length; i++) {
			imgs += "<img class='faces' src='/static/" + data[i] + "' name='" + data[i] + "' width='64px'>";
		}
		$("#smiley-box").html(imgs);
		$("#smiley-box").show();
		$("#smiley-box > .faces").click(
			function() {
				$("#msg").val($("#msg").val() + "[" + $(this).attr("name") + "]");
				$("#smiley-box").hide();
		});
	});
}

function onIncomeMsg(data) {
	console.log("data:" + data);
	var msg = JSON.parse(data);
	if (msg == null) {
		console.log('parsed JSON msg is null');
		return;
	}
        console.log("msg:" + msg);
	payload = msg.p;
	switch (msg.t) {
		case "contacts" :
			if (typeof payload === 'object') {
				if (typeof payload.length === 'number' && !(payload.propertyIsEnumerable('length'))) {
					console.log("payload:" + payload);
					initContactList(payload);
				}
			}
			break;
		case "msg" :
			if (typeof payload === 'object') {
				var body = payload.body;
				var from = payload.from;
				var contact = map[from];
				console.log("from:" + from);
				var containerName = "l-" + from;
				var activeLog = window.document.getElementById(containerName);
				console.log(activeLog);
				$(".msglog").hide();
				if (activeLog != null) {
					console.log(activeLog != null);
					$(activeLog).show();
				} else {
					addNewChatLog(contact);
				}
				window.curContact = contact;
				$("#" + containerName).html($("#" + containerName).html() + "<br/>" + renderMsg(body, "rcvd", contact.n));
			}
			break;
		default: break;
	}
}

function addNewChatLog(contact) {
	$("#wrap").append('<div id="l-' + contact.h + '" class="span11 msglog"></div>');
	$("#l-" + contact.h).append("<div class='log-title'>" + contact.n + "</div>");
}

function initContactList(contacts) {
	$("#contacts").html(null);
	var item;
	for (var i = 0; i < contacts.length; i++) {
		item = contacts[i];
		map[item.h] = item;
		id = "aid" + i;
		$("#contacts").append("<li><a id='" + id + "' href='javascript:;'>" + item.n + "</a></li>");
		$("#contacts > li > #" + id)
			.bind('click', {msg: item}, function(event) {
				contact = event.data.msg;
				window.curContact = contact;
				$(".msglog").hide();
				var activeLog = window.document.getElementById("l-" + contact.h);
				if (activeLog != null) {
					$(activeLog).show();
				} else {
					addNewChatLog(contact);
				}
			});
	}
}

function getContactList() {
	if (window.ws) {
		var data = {
			"a" : "get_contacts"
		};
		window.ws.send(JSON.stringify(data));
	}
}

$(document).ready(function(){
	init();
	$(window).keydown(function(event) {
    // check for escape key
    if (event.which == 27) {
        event.preventDefault();
    }
	});
	$("#msg").keydown(function(e){
		if (e.keyCode == 13 && !e.shiftKey) {
		    e.preventDefault();
            msg = $("#msg").val();
            if (msg != "" && msg.length < 65535) {
		        sendMsg("#msg",window.curContact.h);
            }
		}
	});
});
