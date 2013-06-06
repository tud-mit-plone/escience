(function( $, undefined ) {
  $.notification = function(options) {
    var opts         = $.extend({}, {type: 'notice', time: 5000}, options);
    var o            = opts;
    timeout          = setTimeout('$.notification.removebar()', o.time);
    var message_span = $('<table style="width:100%; height:100%" />').append($('<tr />').append($('<td />').addClass('jbar-content').html(o.message)));
    var wrap_bar     = $('<div />').addClass('jbar jbar-top '+o.type).css("cursor", "pointer");

    wrap_bar.click(function(){$.notification.removebar()});
    wrap_bar.append(message_span).insertBefore($('#container'));
    wrap_bar.hide();
    wrap_bar.fadeIn(700);
  };

  var timeout;
  $.notification.removebar    = function(txt) {
    if($('.jbar-top').length){
      clearTimeout(timeout);
      $('.jbar-top').fadeOut();
    }   
  };
})(jQuery);

