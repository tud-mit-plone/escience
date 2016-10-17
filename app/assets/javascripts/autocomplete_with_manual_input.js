function autocomplete_with_keyevents(html_insert_id, html_autocomplete_id, autocomplete_url, preset,preset_ids) {
     preset = preset.split(',');
     preset_ids = preset_ids.split(',');
     
    for (var i=0;i<preset.length;i++){
      if(preset[i].replace(/\W*/,"") != ""){
        addElementToHtmlElement(html_insert_id,html_autocomplete_id, preset[i], preset_ids[i]);
      }
    }      
    
    autocomplete_keydown_events(html_insert_id,html_autocomplete_id);

    $( html_insert_id+"_visible" ).autocomplete({
      source: function( request, response ) {
          $.ajax({
          url: autocomplete_url,
          dataType: "json",
          data: {
            maxRows: 12,
            q: request.term.replace(/\W*/,"")
          },
          success: function( data ) {
            $("#auto_suggestion").html("");
            $.redmine_social = data;

              response(
                $.map( data, function( item ) {
                  return {
                    id: item["tag"]["id"],
                    label: item["tag"]["name"]
                  }
              }));
          }
        });
      },
      minLength: 2,
      select: function( event, ui ) {
        addElementToHtmlElement(html_insert_id,html_autocomplete_id, ui.item.label, ui.item.id);
        return false;
      },
      open: function() {$( this ).removeClass( "ui-corner-all" ).addClass( "ui-corner-top" );},
      close: function() {$( this ).removeClass( "ui-corner-top" ).addClass( "ui-corner-all" );}
    });
}