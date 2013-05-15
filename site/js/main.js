jQuery(function ($) {
	var $window = $(window);
	$window.resize(resizeVideo);

	var $video = $('#video'),
		$top = $('#top'),
		VIDWIDTH = 1920,
		VIDHEIGHT = 668,
		SCALE = VIDHEIGHT / VIDWIDTH;

	function resizeVideo() {
		$video.css({
			height: SCALE * $window.width() + 'px',
			marginTop: $top.height() + 'px'
		});
	}
	resizeVideo();


	var $buddha = $('#buddha'), startTop = parseInt($buddha.css('top'), 10);
	$window.on('scroll', function () {
		$buddha.css({
			top: (startTop - $window.scrollTop()/2) + 'px'
		});
	});


	$('#tweet-holder').tweets({username: 'idleworks'}, function (data) {
		console.log(data);
		console.log('done');
	});
});