/**
	Collapse the hierarchie tree independently of the hierarchie level where
	the collapsing will be triggered.
 */

$(document).ready(function() {
	$('.trigger').click(function() {
		var OPEN = '&#x25bc;'
		var CLOSED = '&#x25b6;'
		$(this).toggleClass('closed open');
		affectedObjectsClass = $(this).attr('data-for');
		hierarchieTree = new Map([
			["group-description", "user-total-workload-in-group"],
			["user-description", "project-total-workload"],
			["project-description", "issue-workloads"]
		]);
		currentLevel = $(this).parent().attr('class');		
		if ($(this).hasClass('open')) {
			$(this).show();
			$(this).siblings().show();
			nextLevel = hierarchieTree.get(currentLevel);
			nextLevelClass = '.' + nextLevel;
			$(nextLevelClass).each(function(){
				if ($(this).hasClass(affectedObjectsClass + '-open')) {
					$(this).show();
				}
			});
			$(this).html(OPEN);
		}
		else {
			if (currentLevel == 'group-description') {
				hierarchieTree.forEach(function(value, key){
					nextLevelClass = '.' + value;
					$(nextLevelClass).hide();
					current = $(nextLevelClass).find('span.trigger.open').html(CLOSED);
					current.siblings('dl').hide();
				})
				$(this).siblings().hide();
			}
			else {
				$('.' + affectedObjectsClass + '-close').each(function(){
					$(this).hide();
					$(this).find('span.trigger.open').html(CLOSED);
				})
			}
			$(this).html(CLOSED);
		}
	});
});
