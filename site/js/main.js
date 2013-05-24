/*global jQuery, moment, Modernizr*/
jQuery(function ($) {
	var $window = $(window);
	$window.resize(resizeVideo);

	var $video = $('#video'),
		$videoContainer = $('#video-container'),
		$top = $('#top'),
		VIDWIDTH = 1920,
		VIDHEIGHT = 1080,
		VIDHEIGHT_MAX = 600,
		SCALE = VIDHEIGHT / VIDWIDTH,
		TWITTER_ACCOUNT = 'whosyabuddha';

	function resizeVideo() {
		$videoContainer.css({
			height: Math.min(SCALE * $window.width(), VIDHEIGHT_MAX) + 'px'
		});
		$video.css({
			marginTop: $top.outerHeight() + 'px'
		});
	}

	var img = new Image();
	img.onload = resizeVideo;
	img.src = 'img/clean/buddha.png';


	var $scrollElements = $('#buddha, #spotlights'),
		startTop = parseInt($('#buddha').css('top'), 10) || 0,
		scrollSpeed = 1.2;

	if (!Modernizr.touch) {
		if (Modernizr.csstransforms) {
			$window.on('scroll', fancyScrollHandler);
		} else {
			$window.on('scroll', defaultScrollHandler);
		}
	}

	function fancyScrollHandler() {
		$scrollElements.css({
			transform: 'translateY(' + (startTop - $window.scrollTop() / scrollSpeed) + 'px)'
		});
	}

	function defaultScrollHandler() {
		$scrollElements.css({
			top: (startTop - $window.scrollTop() / scrollSpeed) + 'px'
		});
	}


	$('h1').fitText(1.8, {
		maxFontSize: 34
	});


	$('#tweet-holder').tweets({username: TWITTER_ACCOUNT}, function (data) {
		var $tweets = $('.tweet');

		$.each(data, function (index) {
			var $tweet = $tweets.eq(index),
				date = moment(this.created_at);

			$('p', $tweet).html(this.text);
			$('a', $tweet).attr('href', 'http://www.twitter.com/' + TWITTER_ACCOUNT + '/status/' + this.id_str);
			$('time', $tweet).attr('datetime', this.created_at).html(date.format('MMMM Do YYYY, h:mm'));
		});
	});
});