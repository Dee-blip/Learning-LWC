({
	sectionAction : function(component,sectionId,type) {
        var section = component.find(sectionId) ;
        if(type == "hide") {
            $A.util.removeClass(section, 'slds-show');
            $A.util.addClass(section, 'slds-hide');
        } else {
            $A.util.removeClass(section, 'slds-hide');
            $A.util.addClass(section, 'slds-show');    
        }    
    },
})