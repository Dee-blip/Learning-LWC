({
  afterRender: function(component, helper) {
	  this.superAfterRender();
      helper.adjustTableHeight(component);
      helper.adjustTableWidth(component);
      console.log("afer render called");
      
      
	},
    rerender: function(component, helper) {
    	this.superRerender();
		helper.adjustTableHeight(component);
        helper.adjustTableWidth(component);
        window.onresize = helper.adjustTableHeight(component);
        
	}
  
})