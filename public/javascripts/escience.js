// ToolTip - fügt neue Hiweisboxen mittels qTip2 hinzu
function addToolTip() {
  $selector = arguments[0];
  $tooltip = arguments[1];
  
  $position = 'right';
  if (arguments.length == 3) {
    $position = arguments[2];
  }
  switch ($position) {
    case 'right': $direction = 'left'; break;
    case 'left': $direction = 'right'; break;
    case 'top': $direction = 'bottom'; break;
    case 'bottom': $direction = 'top'; break;
  }
  
  $j($selector).qtip({content: {text: $tooltip}, style: {classes: 'ui-tooltip-shadow ui-tooltip-green'}, position: {at:''+$position+' center', my:''+$direction+' center'}});
}

function toggleDivGroup(el) {
  var div = Element.up(el, 'div.group');
  var n = Element.next(div);
  div.toggleClassName('open');
  while (n != undefined && !n.hasClassName('group')) {
    Element.toggle(n);
    n = Element.next(n);
  }
}
