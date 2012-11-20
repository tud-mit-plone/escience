// ToolTip - fügt neue Hiweisboxen mittels qTip2 hinzu
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