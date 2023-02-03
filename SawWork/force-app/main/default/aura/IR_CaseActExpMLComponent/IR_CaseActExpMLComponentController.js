({
	getActExpManualLists : function(component, event, helper) {
		helper.fetchManualLists(component, event, helper);
	},

    onRender: function(component, event, helper){
    	helper.setSectionHeight(component); 
	},

    toggleSection : function(component, event, helper) {
        // dynamically get aura:id name from 'data-auraId' attribute
        var sectionAuraId = event.target.getAttribute("data-auraId");
        // get section Div element using aura:id
        var sectionDiv = component.find(sectionAuraId).getElement();
        //var scrollableDiv = component.find("scrollable");
        var labelDiv = component.find("label");

        /* The search() method searches for 'slds-is-open' class, and returns the position of the match.
         * This method returns -1 if no match is found.
        */
        var sectionState = sectionDiv.getAttribute('class').search('slds-is-open');
        // -1 if 'slds-is-open' class is missing...then set 'slds-is-open' class else set slds-is-close class to element
        if(sectionState == -1){
            sectionDiv.setAttribute('class' , 'slds-section slds-is-open');

						if(labelDiv != undefined){
								for(var i=0;i<labelDiv.length;i++){
								        	labelDiv[i].getElement().setAttribute('style', 'width:40%!important;');
								}
						}
            helper.setSectionHeight(component);
        }else{
            sectionDiv.setAttribute('class' , 'slds-section slds-is-close');
        }
    }

})