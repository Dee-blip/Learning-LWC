({
  afterRender: function(component, helper) {
	  this.superAfterRender();
      helper.adjustTableHeight(component);
      
      
	},
    rerender: function(component, helper) {
    	this.superRerender();
		helper.adjustTableHeight(component);
        helper.adjustTableWidth(component);
        window.onresize = helper.adjustTableHeight(component);
	}
  
})