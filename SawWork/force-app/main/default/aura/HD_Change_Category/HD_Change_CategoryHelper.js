({
	helperMethod : function() {
		
	},
    waiting: function(component) {
        var ele = component.find("Accspinner");
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
        //document.getElementById("Accspinner").style.display = "block";
     },
     
      doneWaiting: function(component) {
            var ele = component.find("Accspinner");
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");
     }
})