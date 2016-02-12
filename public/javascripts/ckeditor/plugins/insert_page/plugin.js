CKEDITOR.plugins.add('insert_page',{init:function(editor){
  editor.addCommand( 'insert_page',new CKEDITOR.dialogCommand('insert_page'));
  var b='insert_page';
  var c=editor.lang.wiki_page;
  editor.ui.addButton('insert_page',{label:c.toolbar,command:b,icon:this.path+'insert_page.png'});

  if (editor.contextMenu) {
			editor.addMenuGroup( 'mygroup', 10 );
			editor.addMenuItem( 'My Dialog',
			{
				label : title_for_wiki_dialog,
				command : 'insert_page',
				group : 'mygroup'
			});
			editor.contextMenu.addListener( function( element )
			{
 				return { 'My Dialog' : CKEDITOR.TRISTATE_OFF };
			});
  }
  CKEDITOR.dialog.add('insert_page', function(api){
  	var dialogDefinition = {
  		title : title_for_wiki_dialog,
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
  					html : text_for_wiki_dialog
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
          e.setAttribute('class','wiki-page makro');
          e.appendHtml(elem);
          api.insertElement(e);
          CKEDITOR.dialog.getCurrent().hide();
    		}
  		},
  		onOk : function() {
  			var textareaObj = this.getContentElement( 'tab1', 'textareaId' );
  			var e = api.document.createElement('span');
        e.setAttribute('class','wiki-page makro');
        e.appendHtml(textareaObj.getValue());
        api.insertElement(e);
  		}
    };
  	return dialogDefinition;
  });
  editor.on( 'doubleclick', function( evt ) {
    if ($(evt.data.element).attr('class')=='wiki-page') alert("Dies ist ein Link zu einer Wiki-Page");
  });
}});