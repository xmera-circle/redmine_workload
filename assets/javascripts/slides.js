$(document).ready(function() {
	$('.trigger').click(function() {
		$(this).toggleClass('closed open');
		affectedObjectsClass = $(this).attr('data-for');
		
		if ($(this).hasClass('open')) {
			$('.' + affectedObjectsClass + '-open').show();
			$(this).html('&#x25bc;');
		}
		else {
			$('.' + affectedObjectsClass + '-close').hide();
			$(this).html('&#x25b6;');
			$affectedObjects.find('.trigger').html('&#x25b6;');
		}
	});
});
