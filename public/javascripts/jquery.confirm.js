$(document).ready(function(){  
  $.rails.allowAction = function(element) {
    if ($(element).attr('data-confirm')) {
      my_custom_confirm_dialog_function(element);
      return false;
    } else {
      return true;
    }
  }
  
  $.rails.confirmed = function(element) {
    $(element).removeAttr('data-confirm');
    $(element).trigger('click.rails');
  }
    
  function my_custom_confirm_dialog_function(element) {
    var message = $(element).attr('data-confirm');
    if ($("#dialog-confirm").length > 0) {
      html = $("#dialog-confirm").html(message);
    } else {
      html = $('<div id="dialog-confirm" title="'+message_title+'">'+message+'</div>');
    }
    html.dialog({
      autoOpen: true,
      show: "fade",
      hide: "fade",
      modal: true,
      width: '400px',
      closeText: "",
       buttons: [{
            text: message_yes,
            click : function() { 
              $.rails.confirmed(element);
              $( this ).dialog( "close" );
            }
          }, {
            text: message_cancel,
            click: function() {
              $( this ).dialog( "close" );
          }}
        ]
    });
  }
});