
jQuery(document).ready(function() {
	jQuery('.trigger').click(function() {
		
		$this = jQuery(this);
		
		$this.toggleClass('closed open');
		
		affectedObjectsClass = $this.attr('data-for');
		$affectedObjects = jQuery('.' + affectedObjectsClass);
		
		if ($this.hasClass('open')) {
			$affectedObjects = jQuery('.' + affectedObjectsClass + '-open');
			$affectedObjects.show();
			
			$this.html('&#x25bc;');
		}
		else {
			$affectedObjects = jQuery('.' + affectedObjectsClass + '-close');
			$affectedObjects.hide();

			$this.html('&#x25b6;');
		}
	});
});