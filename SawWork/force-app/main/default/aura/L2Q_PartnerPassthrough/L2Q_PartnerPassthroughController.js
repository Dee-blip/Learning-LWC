({

    initJS: function (component) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1));
        var sURLVariables = sPageURL.split('&');
        var sParameterName;
        var recordId;
        var i =0;

        const tncSigningCheck = component.get("c.checkIfTNCSigningIsNeeded");
        tncSigningCheck.setParams({
            "poaId": component.get("v.recordId")
        });

        tncSigningCheck.setCallback(this, function (response) {
            const state = response.getState();
            console.log(state);
            if (component.isValid() && state === "SUCCESS") {
                const returnVal = response.getReturnValue();
                console.log(returnVal);
                if(!returnVal.includes('needed'))
                {
                    component.set("v.noSigningNeededMessage", returnVal);
                    component.set("v.tncSigningNeeded", false);
                }
                else
                {
                    component.set("v.tncSigningNeeded", true);
                }
                
            }
        })
        $A.enqueueAction(tncSigningCheck);

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
            if (sParameterName[0] === 'recordId') {
                recordId = sParameterName[1];
            }
        }
        console.log("Param : " + recordId);
        component.set("v.contentVersionId", recordId);

        const fileDownloadUrl = '/partners/s/file-download-page?retUrl=' + window.location + '&id=';
        component.set("v.fileDownloadUrl", fileDownloadUrl);

        const getDataVar = component.get("c.initCon");
        getDataVar.setParams({
            "poaId": component.get("v.recordId")
        });

        getDataVar.setCallback(this, function (response) {
            const state = response.getState();
            console.log(state);
            if (component.isValid() && state === "SUCCESS") {
                let returnVal = response.getReturnValue();
                returnVal.map(function(ele){
                    return (ele.isChecked=false);
                });
                console.log('length'+returnVal.length);
                if(returnVal.length===1)
                {
                    returnVal[0].isChecked=true;
                    console.log('publishedid:'+returnVal[0].ContentDocument.LatestPublishedVersionId);
                    component.set("v.selectedDocId", returnVal[0].ContentDocument.LatestPublishedVersionId);
                }
                console.log(returnVal);
                component.set("v.listOfAttachedFiles", returnVal);
            }
        })
        $A.enqueueAction(getDataVar);
    },


    testerJS: function (component) {
        const getDataVar = component.get("c.createRestEnvelop");
        getDataVar.setParams({
            "name": component.get("v.sendToName"),
            "email": component.get("v.sendToEmail"),
            "sourceId": component.get("v.recordId"),
            "documentId": component.get("v.selectedDocId")
        });

        getDataVar.setCallback(this, function (response) {
            const state = response.getState();
            console.log(state);
            if (component.isValid() && state === "SUCCESS") {
                const returnVal = response.getReturnValue();
                console.log(returnVal);
            }
        })
        $A.enqueueAction(getDataVar);
    },

    sendDocusign: function (component) {

        component.set("v.hasErrors", false);
        component.set("v.afterSend", false);

        const getDataVar = component.get("c.createRestEnvelop");
        
        const emailRegex=/^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        let endCustomerEmail = component.get("v.sendToEmail");
        let endCustomerName = component.get("v.sendToName");
        console.log("name : " + endCustomerName);
        console.log("email : " + endCustomerEmail);
        console.log("sourceId : " + component.get("v.recordId"));
        console.log("documentId : " + component.get("v.selectedDocId"));
        
        if(endCustomerName==="" || endCustomerName === undefined || endCustomerName== null || !endCustomerName.trim())
        {
            component.set("v.hasErrors", true);
            component.set("v.errorMessage", "Please enter a name");
            return;
        }
        if(endCustomerEmail==="" || endCustomerEmail === undefined || endCustomerEmail== null || !endCustomerEmail.trim() || !endCustomerEmail.match(emailRegex))
        {
            component.set("v.hasErrors", true);
            component.set("v.errorMessage", "Please enter a valid email address");
            return;
        }

        getDataVar.setParams({
            "name": endCustomerName,
            "email": endCustomerEmail,
            "sourceId": component.get("v.recordId"),
            "documentId": component.get("v.selectedDocId")
        });

        getDataVar.setCallback(this, function (response) {
            const state = response.getState();
            console.log(state);
            if (component.isValid() && state === "SUCCESS") {
                const returnVal = response.getReturnValue();
                console.log(returnVal);
                if (returnVal.errorMessage !== undefined && returnVal.errorMessage != null && returnVal.errorMessage !== '') {
                    component.set("v.hasErrors", true);
                    component.set("v.errorMessage", returnVal.errorMessage);
                } else if (returnVal.successMessage !== undefined && returnVal.successMessage != null && returnVal.successMessage !== '') {
                    component.set("v.successMessage", returnVal.successMessage);
                }
                component.set("v.afterSend", true);
                //window.open(returnVal);
            }
            else if(state === "ERROR"){
                const returnVal = response.getReturnValue();
                console.log(returnVal);
                component.set("v.hasErrors", true);
                component.set("v.errorMessage", 'An error occurred while sending envelope');
            }
        })
        $A.enqueueAction(getDataVar);
    },

    assignSelectedValue: function (component, event) {
        const target = event.getSource();
        const selectedDocId = target.get("v.value");
        console.log(selectedDocId);
        if (target.get("v.checked")) {
            component.set("v.selectedDocId", selectedDocId);
        }
    },
    back: function(component)
    {
        const action = component.get("c.isCommunity");
        action.setCallback(this, function(response) {
        const isCommunity = response.getReturnValue(); // do any operation needed here
        if(isCommunity)
        {
            window.parent.location = '/partners/' + component.get("v.recordId");
        }
        else
        {
            window.parent.location =component.get("v.recordId");
        }

    });
    $A.enqueueAction(action);
    }
})