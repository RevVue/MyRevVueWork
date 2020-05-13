(function($) {
	
	$.alerts = {
		
		// These properties can be read/written by accessing $.alerts.propertyName from your scripts at any time
		
		verticalOffset: -75,                // vertical offset of the dialog from center screen, in pixels
		horizontalOffset: 0,                // horizontal offset of the dialog from center screen, in pixels/
		repositionOnResize: true,           // re-centers the dialog on window resize
		overlayOpacity: .6,                // transparency level of overlay
		overlayColor: '#000000',               // base color of overlay
		draggable: true,                    // make the dialogs draggable (requires UI Draggables plugin)
		okButton: '&nbsp;Ok&nbsp;',         // text for the OK button
		cancelButton: '&nbsp;Cancel&nbsp;', // text for the Cancel button
		dialogClass: null,                  // if specified, this class will be applied to all dialogs
		
		// Public methods
		
		alert: function(message, title, callback) {
			if( title == null ) title = 'Alert';
			$.alerts._show(title, message, null, 'alert', function(result) {
				if( callback ) callback(result);
			});
		},
		
		confirm: function(message, title, callback) {
			if( title == null ) title = 'Confirm';
			$.alerts._show(title, message, null, 'confirm', function(result) {
				if( callback ) callback(result);
			});
		},
			
		prompt: function(message, value, title, callback) {
			if( title == null ) title = 'Prompt';
			$.alerts._show(title, message, value, 'prompt', function(result) {
				if( callback ) callback(result);
			});
		},
		
		// Private methods
		
		_show: function(title, msg, value, type, callback) {
			
			$.alerts._hide();
			$.alerts._overlay('show');
			
			$("BODY").append(
			  '<div id="popup_container">' +
			    '<h1 id="popup_title"></h1>' +
			    '<div id="popup_content">'+
					'<div id="popup_image"></div>'+
					'<div>' +
						'<div id="popup_message"></div>' +
					'</div>' +
				'</div>' +
			  '</div>');
			
			if( $.alerts.dialogClass ) $("#popup_container").addClass($.alerts.dialogClass);
						
			$("#popup_container").css({
				position: 'absolute',
				zIndex: 9999999,
				padding: 0,
				margin: 0
			});
			if(title == 'Info'){
				$('#popup_image').html('<i class="fa fa-info-circle info"></i>');
			}else if(title == 'Warning'){
				$('#popup_image').html('<i class="fa fa-exclamation-triangle warning"></i>');
			}else if(title == 'Error'){
				$('#popup_image').html('<i class="fa fa-exclamation-triangle error"></i>');
			}else if(title == 'Confirmation'){
				$('#popup_image').html('<i class="fa fa-check-square-o confirmation"></i>');
			}
			$("#popup_title").text(title);
			$("#popup_content").addClass(type);
			$("#popup_message").text(msg);
			$("#popup_message").html( $("#popup_message").text().replace(/\n/g, '<br />') );
			
			$("#popup_container").css({
				minWidth: $("#popup_container").outerWidth(),
				maxWidth: $("#popup_container").outerWidth()
			});
			
			$.alerts._reposition();
			$.alerts._maintainPosition(true);

			switch( type ) {
				case 'alert':
					$("#popup_message").after('<div id="popup_panel"><button type="button" id="popup_ok" class="btn btn-success"><i class="fa fa-check"></i>'+ $.alerts.okButton + '</button></div>');
					$("#popup_ok").click( function() {
						$.alerts._hide();
						callback(true);
					});
					$("#popup_ok").focus().keypress( function(e) {
						if( e.keyCode == 13 || e.keyCode == 27 ) $("#popup_ok").trigger('click');
					});
				break;
				case 'confirm':
					$("#popup_message").after('<div id="popup_panel"><button type="button" id="popup_ok" class="btn btn-success"><i class="fa fa-check"></i>' + $.alerts.okButton + '</button>&nbsp &nbsp <button type="button" class="btn btn-success" id="popup_cancel"><i class="fa fa-remove"></i>'+ $.alerts.cancelButton + '</button></div>');
					$("#popup_ok").click( function() {
						$.alerts._hide();
						if( callback ) callback(true);
					});
					$("#popup_cancel").click( function() {
						$.alerts._hide();
						if( callback ) callback(false);
					});
					$("#popup_ok").focus();
					$("#popup_ok, #popup_cancel").keypress( function(e) {
						if( e.keyCode == 13 ) $("#popup_ok").trigger('click');
						if( e.keyCode == 27 ) $("#popup_cancel").trigger('click');
					});
				break;
			}
			// comment by avanish (12/18/2015)
			// Make draggable
			/* if( $.alerts.draggable ) {
				try {
					//$("#popup_container").draggable({ handle: $("#popup_title") });
					//$("#popup_title").css({ cursor: 'move' });
				} catch(e) { /* requires jQuery UI draggables  }
			} */
		},
		
		_hide: function() {
			$("#popup_container").remove();
			$.alerts._overlay('hide');
			$.alerts._maintainPosition(false);
		},
		
		_overlay: function(status) {
			switch( status ) {
				case 'show':
					$.alerts._overlay('hide');
					$("BODY").append('<div id="popup_overlay"></div>');
					$("#popup_overlay").css({
						position: 'absolute',
						zIndex: 9999998,
						top: '0px',
						left: '0px',
						width: '100%',
						height: '100%',
						background: $.alerts.overlayColor,
						opacity: $.alerts.overlayOpacity
					});
				break;
				case 'hide':
					$("#popup_overlay").remove();
				break;
			}
		},
		
		_reposition: function() {
			var top = (($(window).height() / 2) - ($("#popup_container").outerHeight() / 2)) + $.alerts.verticalOffset;
			var left = (($(window).width() / 2) - ($("#popup_container").outerWidth() / 2)) + $.alerts.horizontalOffset;
			if( top < 0 ) top = 0;
			if( left < 0 ) left = 0;
						
			$("#popup_container").css({
				top: top + 'px',
				left: left + 'px'
			});
			$("#popup_overlay").height( '100%');
		},
		
		_maintainPosition: function(status) {
			if( $.alerts.repositionOnResize ) {
				switch(status) {
					case true:
						$(window).bind('resize', $.alerts._reposition);
					break;
					case false:
						$(window).unbind('resize', $.alerts._reposition);
					break;
				}
			}
		}
		
	}
	
	// Shortuct functions
	jAlert = function(message, title, callback) {
		$.alerts.alert(message, title, callback);
	}
	
	jConfirm = function(message, title, callback) {
		$.alerts.confirm(message, title, callback);
	};
	
})(jQuery);