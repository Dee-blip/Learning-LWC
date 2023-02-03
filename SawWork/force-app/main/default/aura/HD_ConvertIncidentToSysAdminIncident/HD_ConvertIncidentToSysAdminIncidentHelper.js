({
	helperMethod : function() {
		
	},
    waiting: function(component) {
        var ele = component.find("Accspinner");
        console.log("waiting called");
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
     },
     
      doneWaiting: function(component) {
            var ele = component.find("Accspinner");
          	console.log(ele);
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");
     }
})