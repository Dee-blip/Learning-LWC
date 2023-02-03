({
	click : function(component, event, helper) {
		
		// var clickEvt = $A.get("e.c:MyOutputClickEvt");
  //       clickEvt.setParams({ "fieldid":component.get("v.recordid")});
  //       clickEvt.fire();

        //Firing Component Event.
        console.log('inside myoutputfieldcontroller.click function componentEvent.')
		var clickEvt2 = component.getEvent("compEventOutputField");
		clickEvt2.setParams({ "fieldid":component.get("v.recordid")});
		console.log('clickEvt2=' + JSON.stringify(clickEvt2));
		clickEvt2.fire();
	}
})