$(document).ready(function() {
	$(window).resize(checkDockNav);
	$(window).scroll(checkDockNav);
});

function checkDockNav() {
	if ($(window).scrollTop() > 165) {
	 $('#navigation').css("position","fixed");
	 $('#navigation').css("top","0");
	 $('#navigation').css("width","100%");
	 $('#navigation').css("z-index","16");
	 $('#main_navigation').css("margin-bottom","25px");
	 $('#navigation').css("background-color","#7DB414");
	 $('#navigation a').css("color","#FFF");
	 $('#quick-search input[type="submit"]').css('background','url(/images/arrow_collapsed_white.png) 20%');
  } else {
	 $('#navigation').css("position","relative");
	 $('#main_navigation').css("margin-bottom","0px");
	 $('#navigation').css("background-color","#E9E9E9");
	 $('#navigation a').css("color","#707070");
	 $('#quick-search input[type="submit"]').css('background','url(/images/arrow_collapsed.png) 20%');
  }
}

function addToolTip_withTitle() {
  selector = arguments[0];
  position = 'right';
  if (arguments.length == 2) {
    position = arguments[1];
  }
  $(selector).each(function() {
    addToolTip(selector, this.title, position);
  });
}

function addToolTip() {
  selector = arguments[0];
  tooltip = arguments[1];
  
  position = 'right';
  if (arguments.length == 3) {
    position = arguments[2];
  }
  switch (position) {
    case 'right': direction = 'left'; break;
    case 'left': direction = 'right'; break;
    case 'top': direction = 'bottom'; break;
    case 'bottom': direction = 'top'; break;
  }
  
  $(selector).qtip({content: {text: tooltip}, style: {classes: 'ui-tooltip-shadow ui-tooltip-green'}, position: {at:''+position+' center', my:''+direction+' center'}});
}

function toggleDivGroup(el, num) {
  var div = $(el).parent();
  div.toggleClass('open');
  var hiddenLinks = div.parent().find('div.listOfIssues.element_'+num);
  hiddenLinks.toggle();
}

function tagItForUs(el,text,id) {
  jQuery(el).tagit({
     tagSource: function(request, response) {
       jQuery.ajax({
          url:        "/metatagssearch.json",
          dataType:   "json",
          data:       { q: request.term },
          success: function(data) {
						response(jQuery.map( data, function( item ) {
               return item.meta_information.meta_information;
						}));
          }
       });
     },
     allowSpaces: false, 
     select:true, 
     sortable:true, 
     itemName: "attachments",
     fieldName: id+"][meta_information", 
     maxLength: 400,
     placeholderText: text
  });
}

	function addUserToReceivers(message, id) {
		var element = $( "<div class='name_element element_"+id+"' />" ).text( message );
		var delete_item = $( "<div class='delete_button element_"+id+"' />" ).prependTo( element ).click(function(){
		 var id = $(this).attr('class').split(' ')[1].substring(8);
		 var olddata_arr = $("#user_message_receiver").val().split(',');
		 if (olddata_arr.length == 0) {
		   $("#user_message_receiver").val("");
		 } else {
			 olddata_arr.splice($.inArray(id, olddata_arr), 1 );
			 $("#user_message_receiver").val(olddata_arr.join(','));
			 $(this).parent().remove();
		 }
	  });
		var oldelements = $("#recipient_autocomplete").find(".name_element");
		if (oldelements.length < 1) element.prependTo( "#recipient_autocomplete" );
		else element = oldelements.last().after(element);
		$( "#recipient_autocomplete" ).scrollTop( 0 );
		var olddata = $("#user_message_receiver").val();
		if (olddata != "") olddata = olddata+","+id;
		else olddata = id;
		$("#user_message_receiver").val(olddata);
		$("#user_message_receiver_visible").val("");
	}