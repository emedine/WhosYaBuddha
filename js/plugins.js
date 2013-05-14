// Avoid `console` errors in browsers that lack a console.
(function() {
    var method;
    var noop = function () {};
    var methods = [
        'assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error',
        'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
        'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',
        'timeStamp', 'trace', 'warn'
    ];
    var length = methods.length;
    var console = (window.console = window.console || {});

    while (length--) {
        method = methods[length];

        // Only stub undefined methods.
        if (!console[method]) {
            console[method] = noop;
        }
    }

    Modernizr.addTest('pointerevents',function(){
        return document.documentElement.style.pointerEvents === '';
    });



}());

// Place any jQuery/helper plugins in here.

/*
*   jQuery Tweet v0.1
*   written by Diego Peralta
*
*   Copyright (c) 2010 Diego Peralta (http://www.bahiastudio.net/)
*   Dual licensed under the MIT (MIT-LICENSE.txt)
*   and GPL (GPL-LICENSE.txt) licenses.
*   Built using jQuery library 
*
*   Options:
*       - before (string): HTML code before the tweet.
*       - after (string): HTML code after the tweet.
*       - tweets (numeric): number of tweets to display.
*   
*   Example: 
*   
*       <script type="text/javascript" charset="utf-8">
*           $(document).ready(function() {
*               $('#tweets').tweets({
*                   tweets:4,
*                   username: "diego_ar"
*               });
*           });
*       </script>
*
*/
(function($){
    $.fn.tweets = function(options, callback) {
        $.ajaxSetup({ cache: true });
        var defaults = {
            tweets: 4,
            before: "<li>",
            after: "</li>"
        };
        var optionsWithDefaults = $.extend(defaults, options);
        return this.each(function() {
            var obj = $(this);
            $.getJSON('http://api.twitter.com/1/statuses/user_timeline.json?callback=?&screen_name='+optionsWithDefaults.username+'&count=' + optionsWithDefaults.tweets,
                function(data) {
                    if (callback instanceof Function) {
                        callback(data);
                    } else {
                        $.each(data, function(i, tweet) {
                            if(tweet.text !== undefined) {
                                $(obj).append(optionsWithDefaults.before+tweet.text+optionsWithDefaults.after);
                            }
                        });
                    }
                }
            );
        });
    };
})(jQuery);