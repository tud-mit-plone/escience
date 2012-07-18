(function( jQuery, undefined ) {
   jQuery.notification = function(options) {
	var opts = jQuery.extend({}, {type: 'notice', time: 3000}, options);
        var o            = opts;
        timeout          = setTimeout('jQuery.notification.removebar()', o.time);
        var message_span = jQuery('<span />').addClass('jbar-content').html(o.message);
        var wrap_bar     = jQuery('<div />').addClass('jbar jbar-top '+o.type).css("cursor", "pointer");

	wrap_bar.click(function(){
        	jQuery.notification.removebar()
        });

    	wrap_bar.append(message_span).hide()
        	.insertBefore(jQuery('#container')).fadeIn('fast');
    	};

    var timeout;
    jQuery.notification.removebar    = function(txt) {
        if(jQuery('.jbar-top').length){
            clearTimeout(timeout);

            jQuery('.jbar-top').fadeOut('fast',function(){
                jQuery(this).hide();
            });
        }   
    };
})(jQuery);

