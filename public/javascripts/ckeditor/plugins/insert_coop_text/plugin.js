CKEDITOR.plugins.add('insert_coop_text',{init:function(editor){
  editor.addCommand( 'insert_coop_text',new CKEDITOR.dialogCommand('insert_coop_text'));
  var b='insert_coop_text';
  var c=editor.lang.coop_text;
  editor.ui.addButton('insert_coop_text',{label:c.toolbar,command:b,icon:this.path+'insert_coop_text.png'});

  if (editor.contextMenu) {
			editor.addMenuGroup( 'mygroup', 10 );
			editor.addMenuItem( 'My Dialog',
			{
				label : title_for_coop_text_dialog,
				command : 'insert_coop_text',
				group : 'mygroup'
			});
			editor.contextMenu.addListener( function( element )
			{
 				return { 'My Dialog' : CKEDITOR.TRISTATE_OFF };
			});
  }
  CKEDITOR.dialog.add('insert_coop_text', function(api){
  	var dialogDefinition = {
  		title : title_for_coop_text_dialog,
  		minWidth : 390,
  		minHeight : 130,
  		contents : [{
  			id : 'tab1',
  			label : 'Label',
  			title : 'Title',
  			expand : true,
  			padding : 0,
  			elements :[{
  					type : 'html',
  					html : text_for_coop_text_dialog
  				},{
  					type : 'textarea',
  					id : 'textareaId',
  					rows : 4,
  					cols : 40
  			}]
  		}],
  		buttons : [ CKEDITOR.dialog.okButton, CKEDITOR.dialog.cancelButton ],
  		onShow: function() {
    		var elem= api.getSelection().getSelectedText();
    		if (elem != "") {
    			var e = api.document.createElement('span');
          e.setAttribute('class','coop-text makro fa-file-text-o fa');
          e.appendHtml(elem);
          api.insertElement(e);
          CKEDITOR.dialog.getCurrent().hide();
    		}
  		},
  		onOk : function() {
  			var textareaObj = this.getContentElement( 'tab1', 'textareaId' );
  			var e = api.document.createElement('span');
        e.setAttribute('class','coop-text makro fa-file-text-o fa');
        e.appendHtml(textareaObj.getValue());
        api.insertElement(e);
  		}
    };
  	return dialogDefinition;
  });
  editor.on( 'doubleclick', function( evt ) {
    if ($(evt.data.element).attr('class')=='coop-text') alert("Dies ist ein Platzhalter für ein kooperatives Textdokument.");
  });
}});