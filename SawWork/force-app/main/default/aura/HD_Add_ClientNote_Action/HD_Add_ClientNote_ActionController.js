({
	addNewCLientNote : function(component, event, helper) {
		var incidentId = component.get("v.recordId");
        var note = component.find("noteInput").get("v.value");
        console.log(incidentId);
        console.log(note);
        if(note.trim()==""){
           var input= component.find("noteInput");
           input.set("v.errors", [{message:"Please write Something"}]);
        }else{
           var input= component.find("noteInput");
           input.set("v.errors", null);
           helper.addNote(component, event);
        }
	}
})