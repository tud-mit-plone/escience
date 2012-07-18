// ToolTip - fügt neue Hiweisboxen mittels qTip2 hinzu
function addToolTip($class, $text) {
  $j($class).qtip({content: {text: $text}, style: {classes: 'ui-tooltip-shadow ui-tooltip-green'}, position: {at:'right center', my:'left center'}});
}