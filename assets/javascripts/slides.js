/**
	Toggle along the hierarchie tree.
	When opening, open level by level. When closing, close the item with all 
	lower levels at once.
 */

$(document).ready(function() {
	$('.trigger').click(function() {
		var OPENED = '&#x25bc;'
		var CLOSED = '&#x25b6;'
		$(this).toggleClass('closed opened');

		identifier = $(this).attr('data-for');
		identifierClasses = identifier.trim().replace(/\s/g, ".");

		// topDownHierarchieChain shows current hierarchie level on the left and the css
		// class of the next hierarchie level on the right hand side.
		topDownHierarchieChain = new Map([
			["group-description " + identifier, ".user-total-workload-in-" + identifierClasses],
			["user-description " + identifier, ".project-total-workload." + identifierClasses],
			["project-description " + identifier, ".issue-workloads." + identifierClasses]
		]);

		// bottomUpHierarchies shows current hierarchie level on the left and all  
		// lower hierarchie levels on the right hand side.
		bottomUpHierarchieChain = new Map([
			["group-description " + identifier, [".issue-workloads." + identifierClasses, 
																					 ".project-total-workload." + identifierClasses, 
																					 ".user-total-workload-in-" + identifierClasses]],
			["user-description " + identifier, [".issue-workloads." + identifierClasses,
																					".project-total-workload." + identifierClasses]],
			["project-description " + identifier, [".issue-workloads." + identifierClasses]]
		]);

		currentHierarchieLevel = $(this).parent().attr('class');

		if ($(this).hasClass('opened')) {
			$(this).show();
			// Shows additional info
			$(this).siblings().show();
			// Reveals the next hierarchie level 
			nextHierarchieLevelClass = topDownHierarchieChain.get(currentHierarchieLevel);
			$(nextHierarchieLevelClass).each(function(){
				$(this).show(); // but keep its 'children' closed if any
				$(this).siblings('.invisible-issues-summary.' + identifierClasses).show();
			});
			$(this).html(OPENED);
		}
		else {
			lowerHierarchieLevelClasses = bottomUpHierarchieChain.get(currentHierarchieLevel);
			// Collapses all lower levels of the currentHierarchieLevel at once 
			// as defined in bottomUpHierarchieChain.
			lowerHierarchieLevelClasses.forEach(function(css){
				$(css).hide();
				$(css).siblings('.invisible-issues-summary.' + identifierClasses).hide();
				currentHierarchieLevel = $(css).find('span.trigger.opened');
				currentHierarchieLevel.html(CLOSED);
				currentHierarchieLevel.siblings('dl').hide();
			})
			$(this).siblings().hide();
			$(this).html(CLOSED);
		}
	});
});
