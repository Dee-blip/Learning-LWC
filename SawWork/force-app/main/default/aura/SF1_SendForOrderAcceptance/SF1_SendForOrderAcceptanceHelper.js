({
    getInitialValidation: function(component, event, helper) {
        var getInitialVals = component.get("c.getInitialValidation");
        
        getInitialVals.setParams({
            "orderApprovalId": component.get("v.orderApprovalId")
        });
        
        getInitialVals.setCallback(this, function(response) {
            var state = response.getState();
            console.log(state);
            var returnVal = response.getReturnValue();
            
            if (component.isValid() && state === "SUCCESS") {
                var returnValObj = JSON.parse(returnVal);
                if (returnValObj.errorOccured == 'false') {
                    helper.setAttachementList(component, event, helper, JSON.parse(returnValObj.oa_AttachmentList));
                    var htmlDataObj = JSON.parse(returnValObj.emailData);
                    if (htmlDataObj.contactName != null) {
                        htmlDataObj.contactName = { Name: htmlDataObj.contactName, Id: htmlDataObj.contactId };
                    }
                    component.set("v.htmlDataObj", htmlDataObj);
                    console.log(htmlDataObj);
                    component.set("v.associatedOppty", JSON.parse(returnValObj.oaAssociatedOppty));
                }
                
                component.set("v.returnMessage", returnValObj.returnMessage);
                component.set("v.errorOccured", returnValObj.errorOccured);
                component.set("v.afterCallback", true);
            }
        });
        $A.enqueueAction(getInitialVals);
    },
    
    setMapOfAttachmentType: function() {
        var mapObject = new Map();
        // set map for content type v/s slds icon names
        mapObject.set('msg', 'doctype:word');
        mapObject.set('vnd.openxmlformats-officedocument.wordprocessingml.document', 'doctype:word');
        mapObject.set('gzip', 'doctype:zip');
        mapObject.set('text', 'doctype:txt');
        mapObject.set('plain', 'doctype:txt');
        mapObject.set('pdf', 'doctype:pdf');
        mapObject.set('vnd.ms-excel', 'doctype:excel');
        mapObject.set('png', 'doctype:image');
        
        return mapObject;
    },
    
    setAttachementList: function(component, event, helper, attachmentList) {
        var mapObject = helper.setMapOfAttachmentType();
        
        for (var index in attachmentList) {
            //updated selected attachement if any defaultly
            if (attachmentList[index].checked) {
                var selectedAttachmentIds = component.get("v.selectedAttachmentIds");
                selectedAttachmentIds.push(attachmentList[index].attach.ContentDocumentId);
                component.set("v.selectedAttachmentIds", selectedAttachmentIds);
            }
            // get the type of slds-icon
            console.log('Att: ' + attachmentList[index].attach.ContentDocument.LatestPublishedVersion.FileExtension);
            if (mapObject.get(attachmentList[index].attach.ContentDocument.LatestPublishedVersion.FileExtension) == null || attachmentList[index].attach.ContentDocument.LatestPublishedVersion.FileExtension == 'UNKNOWN') {
                attachmentList[index].attach.AttachmentType = 'doctype:unknown';
            } else {
                attachmentList[index].attach.AttachmentType = mapObject.get(attachmentList[index].attach.ContentDocument.LatestPublishedVersion.FileExtension);
            }
        }
        console.log(attachmentList[0]);
        component.set("v.oaAttachmentList", attachmentList);
    },
    
})