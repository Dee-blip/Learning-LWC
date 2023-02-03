({
    handleUploadFinish : function(component, event) {
        component.set("v.showLoadingSpinner", true);

        const action = component.get("c.updateTags");
        //const uploadedFiles = event.detail.files;
        //alert("upload finished : " + JSON.stringify(uploadedFiles));
        console.log("upload finished");
        let uF = event.getParam("files");
        console.log(uF[0].contentVersionId);


        
        action.setParams({
            'contentVersionId': uF[0].contentVersionId,
            'recordId' : component.get("v.recordId")
        });
      
        action.setCallback(this, function (response) {
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                component.set("v.showLoadingSpinner", false);

                const returnVal = response.getReturnValue();
                console.log(returnVal);
                component.set("v.hasErrors", false);
                component.set("v.showSuccessMessage", true);
                component.set("v.successMessage", returnVal);
                $A.get("e.force:closeQuickAction").fire();  
                $A.get('e.force:refreshView').fire();  
            } else {
                component.set("v.showLoadingSpinner", false);

                const returnVal = response.getError();
                console.log(returnVal);
                component.set("v.hasErrors", true);
                component.set("v.errorMessage", "An Error occured while uploading the file: "+returnVal[0].message);
            }
        });
        $A.enqueueAction(action);
    }
})