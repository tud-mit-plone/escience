$(document).ready(function() {
	$(window).resize(checkDockNav);
	$(window).scroll(checkDockNav);
  $.fn.qtip.styles.eScience = {
    background: '#c7da9c',
    color: 'black',
    textAlign: 'block',
    border: {width: 2, radius: 2, color: '#7DB414'},
    tip: {color: '#7DB414', size: {x: 8, y : 8}}
  }
});

function upload_attachment(el) {
  if (!$('.add_attachment').hasClass('disabled')) {
    $('#attachments_form').ajaxSubmit({
      beforeSubmit: function(a,f,o) {o.dataType = 'json';},
      complete: function(XMLHttpRequest, textStatus) {
        var xmlhttp = XMLHttpRequest;
        if (xmlhttp.readyState==4 && xmlhttp.status==200) {
           eval(xmlhttp.responseText);
        }
      }
    });
  }
}

function updateDraggableMessages() {
  $('.draggable').draggable({
    cursor: 'alias',
    revert: 'invalid',
    cursorAt: { top: 5, left: 5 },
    helper: function( event ) {return $("<div class='mail_icon\'></div>");}
  });
}

function checkDockNav() {
  $('#navigation').toggleClass('fixed', $(window).scrollTop() > 145);
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
  if ($.type(tooltip) === "string") {
    content = {text: tooltip};
  } else {
    content = tooltip;
  }
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
  $(selector).qtip({
    content: content,
    style: {
      name: 'eScience',
      tip: ''+direction+'Middle',
    },
    position: {
      corner: {
        target:''+position+'Middle',
        tooltip:''+direction+'Middle'
      }
    }
  });
}

function update_crop(coords) {
  var rx = 180/coords.w;
  var ry = 180/coords.h;
  var img_width = $("#cropbox").width()
  var img_height = $("#cropbox").height()
  var ox = $("#original_width").val() / img_width;
  var oy = $("#original_height").val() / img_height;
  $('#preview').css({
    width: Math.round(rx * img_width) + 'px',
    height: Math.round(ry * img_height) + 'px',
    marginLeft: '-' + Math.round(rx * coords.x) + 'px',
    marginTop: '-' + Math.round(ry * coords.y) + 'px'
  });
  $("#crop_x").val(Math.round(coords.x * ox));
  $("#crop_y").val(Math.round(coords.y * oy));
  $("#crop_w").val(Math.round(coords.w * ox));
  $("#crop_h").val(Math.round(coords.h * oy));
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
    function is_input_in_autocomplete(html_autocomplete_id, message){
      var flag = false;
      $(html_autocomplete_id+" .name_element").each(function() {

        if($(this).text() == message){
          flag = true;
          return false;
        }
      });
      return flag;
    }

    function autocomplete_keydown_events(html_insert_id, html_autocomplete_id) {
    $(html_insert_id+"_visible").on("keydown",function(e) {

      /* 32 => space, 13 => enter */

      if (e.which == 32 || e.which == 13 && (e.preventDefault() || 1)){
        var inserted_one = false;
        input = $(html_insert_id+"_visible").val();

        $.map($.redmine_social, function (auto_suggest) {
          if(auto_suggest["tag"]["name"] == input ){
            addElementToHtmlElement(html_insert_id,html_autocomplete_id, auto_suggest["tag"]["name"], auto_suggest["tag"]["id"]);
            inserted_one = true;
            return false;
          }
        });
        if(inserted_one == false){
          addElementToHtmlElement(html_insert_id,html_autocomplete_id,input, input);
        }
        $(html_insert_id+"_visible").val("");
      }
    });
    }

	function addElementToHtmlElement(html_insert_id,html_autocomplete_id, message, id) {
        if(is_input_in_autocomplete(html_autocomplete_id, message) == true){
          return;
        }
	  var element = $( "<div class='name_element element_"+id+"' />" ).text( message );
	  var delete_item = $( "<div class='delete_button element_"+id+"' />" ).prependTo( element ).click(function(){
	  var id = $(this).attr('class').split(' ')[1].substring(8);
	  var olddata_arr = $(html_insert_id).val().split(',');

         if (olddata_arr.length == 0) {
	    $(html_insert_id).val("");
	  }else{
           olddata_arr.splice($.inArray(id, olddata_arr), 1 );
	    $(html_insert_id).val(olddata_arr.join(','));
	    $(this).parent().remove();
	  }
	  });
	  var oldelements = $(html_autocomplete_id).find(".name_element");
	  if (oldelements.length < 1){
          element.prependTo(html_autocomplete_id);
         }else{
           element = oldelements.last().after(element);
         }
	   $(html_autocomplete_id).scrollTop( 0 );
	   var olddata = $(html_insert_id).val();
         if (olddata != ""){
           olddata = olddata+","+id;
         }else{
           olddata = id;
         }

          $(html_insert_id).val(olddata);
	   $(html_insert_id+"_visible").val("");
	}

    function addUserToReceivers(message, id) {
        addElementToHtmlElement('#user_message_receiver','#recipient_autocomplete', message, id);
    }

	/*function addUserToReceivers(message, id) {
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
	}*/
