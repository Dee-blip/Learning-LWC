({
    doInit: function(component, event, helper) {
        
        window.addEventListener("message", function(vfevent) {
            if(vfevent.data === 'false'){
                component.set("v.isModalOpen", false);
            }
        }, false);
        
        //let recordId = component.get("v.recordId");
        //var urlParams = new URLSearchParams(window.location.search);
        var akamPDId = window.location.href.split('recordId=')[1];
        var actionGetPDID = component.get("c.getPDID");
        actionGetPDID.setParams({
            pdAkamId: akamPDId
        }); 
        
        actionGetPDID.setCallback(this,function(responsePDID){
            if(responsePDID.getState()==="SUCCESS"){
                if(responsePDID.getReturnValue() != 'NOT AUTHORIZED'){
                    component.set("v.isPDUnAvailable",false);
                    component.set("v.recordId",responsePDID.getReturnValue());
                    helper.fetchRecords(component, event, helper);
                }
                else{
                    component.set("v.isPDUnAvailable",true);
                    //helper.fetchRecords(component, event, helper);
                }
                let actionIsCommunity = component.get("c.getCommunityAccess");
                actionIsCommunity.setCallback(this, function(responseIsCommunity){
                    if(responseIsCommunity.getState()==="SUCCESS"){
                        if(responseIsCommunity.getReturnValue() === true){
                            component.set("v.displayInstruction",true);
                        }
                    }
                });
                $A.enqueueAction(actionIsCommunity);
            }
            else if(responsePDID.getState()==="ERROR"){
                let actionIsCommunity = component.get("c.getCommunityAccess");
                actionIsCommunity.setCallback(this, function(responseIsCommunity){
                    if(responseIsCommunity.getState()==="SUCCESS"){
                        if(responseIsCommunity.getReturnValue() === true){
                            component.set("v.displayInstruction",true);
                        }
                    }
                });
                $A.enqueueAction(actionIsCommunity);

                helper.fetchRecords(component, event, helper);
                //component.set("v.isPDUnAvailable",true);
            }
        });
        $A.enqueueAction(actionGetPDID);
    },
    
    onclickdiv: function(component, event, helper) {
        component.set("v.HandlerId", event.target.id);
    },
    
    parentMethod:function(component, event, helper)
    {
        component.set("v.spinner", false);
        component.set("v.confirmMasterEdit", false);
        let params = event.getParam('arguments');
        if (params) {
            if(params.isSuccess == true){
                var a = component.get('c.doInit');
                component.set("v.displayMasterEdit",true);
                $A.enqueueAction(a);
            }
        }
    },
    
    /*expandAllInstructions: function(component){
        component.find("childInstructions").expandAll();   

    },  
    collapseAllInstructions: function(component){
        component.find("childInstructions").collapseAll();  
    },*/

    expandAll: function(component, event, helper){
        let activeSections = component.get("v.activeSections");
        let idArray = [];
        let result = component.get("v.ExistingSHMap");
        Object.keys(result).forEach(key => {
            idArray.push(result[key].SHMap.Id);
        });
        component.set("v.activeSections", idArray);
    },  
    collapseAll: function(component, event, helper){
        let activeSections = component.get("v.activeSections");
        let idArray = [];
        let result = component.get("v.ExistingSHMap");
        Object.keys(result).forEach(key => {
            idArray.push(result[key].SHMap.Id);
        });
        component.set("v.activeSections", []);
    },
    
    ShowHideAll: function(component, event, helper) {
        let activeSections = component.get("v.activeSections");
        let idArray = [];
        let result = component.get("v.ExistingSHMap");
        Object.keys(result).forEach(key => {
            idArray.push(result[key].SHMap.Id);
        });
        if (activeSections.length === 0) {
            component.set("v.activeSections", idArray);
        } else {
            component.set("v.activeSections", []);
        }
    },
    
    //to filter the Situation based on search term
    dofilter: function(component, event, helper) {
        helper.filterRecords(component, event, helper);
    },
    
    ShowSituationtoHandlerMapping: function(component, event, helper) {
        component.set("v.isModalOpen", true);
    },
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false
        component.set("v.isModalOpen", false);
    },
    closeConfirmation:function(component, event, helper) {
        component.set("v.confirmMasterEdit", false);
    },
    openConfirmation:function(component, event, helper) {
        component.set("v.confirmMasterEdit", true);
    },
    editHandlers: function(component, event, helper) {
        component.set("v.displayMasterEdit",false);
        var handlerCmp = component.find('handlerCmpId');
        if(handlerCmp.length != undefined){
            for(var i = 0;i < handlerCmp.length;i++){
                /*let showEscalationList = false;
                let showIgnoreCondition = false;
                let handlerType = handlerCmp[i].get('v.HandlerDetails').Handler_Type__r.Name
                if(handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
                    showIgnoreCondition = "true;"
                }
                if(handlerType == 'Attack Handler Type' ||handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
                    showEscalationList = "true";
                }
                handlerCmp[i].masterEdit(showIgnoreCondition,showEscalationList);*/
                handlerCmp[i].masterEdit();
            }
        }
        else{
            /*let showEscalationList = false;
            let showIgnoreCondition = false;
            let handlerType = handlerCmp.get('v.HandlerDetails').Handler_Type__r.Name
            if(handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
                showIgnoreCondition = "true";
            }
            if(handlerType == 'Attack Handler Type' ||handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
                showEscalationList = "true";
            }
            handlerCmp.masterEdit(showIgnoreCondition,showEscalationList);*/
            handlerCmp.masterEdit();
        }
    },
    updateHandlers: function(component, event, helper) {
        component.set("v.spinner", true);
        let instructionWrapperList = [];
        //var handlerInstructionMap = new Map(); 
        //component.set("v.displayMasterEdit",true);
        var handlerCmp = component.find('handlerCmpId');
        if(handlerCmp.length != undefined){
            for(var i = 0;i < handlerCmp.length;i++){
                let instructionWrapper = {
                    handlerId: '',
                    situationId: '',
                    situationInstruction: '',
                    ignoreCondition: '',
                };
                //var currentHandler = i;
                //var totalHandlers = handlerCmp.length;
                let situationSuggestionCapture = '';
                let ignoreSuggestionCapture = '';
                //situationSuggestionCapture = handlerCmp[i].get('v.situationSuggestionCapture');
                //ignoreSuggestionCapture = handlerCmp[i].get('v.ignoreSuggestionCapture');
                
                situationSuggestionCapture = (handlerCmp[i].get('v.situationSuggestionCapture') != undefined) ? handlerCmp[i].get('v.situationSuggestionCapture') : '';
        		ignoreSuggestionCapture = (handlerCmp[i].get('v.ignoreSuggestionCapture') != undefined) ? handlerCmp[i].get('v.ignoreSuggestionCapture') : '';
                
                if((situationSuggestionCapture.replace( /(<([^>]+)>)/ig, '')).replace(/\s/g, '').length == 0)
                	situationSuggestionCapture = (situationSuggestionCapture.replace(/(<([^>]+)>)/ig, '')).trim();
                if((ignoreSuggestionCapture.replace( /(<([^>]+)>)/ig, '')).replace(/\s/g, '').length == 0)
                	ignoreSuggestionCapture = (ignoreSuggestionCapture.replace(/(<([^>]+)>)/ig, '')).trim();
                
                //var instructionMap = new Map(); 
                //instructionMap.set("Situation Instruction",situationSuggestionCapture);
                //instructionMap.set("Ignore Condition",ignoreSuggestionCapture);
                //handlerInstructionMap.set(component.get('v.lFilteredSHMap')[i].SHMap.Handler__c,instructionMap);
                
                instructionWrapper.handlerId = component.get('v.lFilteredSHMap')[i].SHMap.Handler__c;
                instructionWrapper.situationId = component.get('v.lFilteredSHMap')[i].SHMap.Situation__c;
                instructionWrapper.situationInstruction = situationSuggestionCapture;
                instructionWrapper.ignoreCondition = ignoreSuggestionCapture;
                instructionWrapperList.push(instructionWrapper);
                
                //handlerCmp[i].updateMasterEdit(situationSuggestionCapture,ignoreSuggestionCapture,handlerInstructionMap,currentHandler,totalHandlers);
                if(i == handlerCmp.length-1)
                    handlerCmp[i].updateMasterEdit(instructionWrapperList);
            }
        }
        else{
            let instructionWrapper = {
                handlerId: '',
                situationId: '',
                situationInstruction: '',
                ignoreCondition: '',
            };
            let situationSuggestionCapture = '';
            let ignoreSuggestionCapture = '';
            //situationSuggestionCapture = handlerCmp.get('v.situationSuggestionCapture');
            //ignoreSuggestionCapture = handlerCmp.get('v.ignoreSuggestionCapture');
            
            situationSuggestionCapture = (handlerCmp.get('v.situationSuggestionCapture') != undefined) ? handlerCmp.get('v.situationSuggestionCapture') : '';
        	ignoreSuggestionCapture = (handlerCmp.get('v.ignoreSuggestionCapture') != undefined) ? handlerCmp.get('v.ignoreSuggestionCapture') : '';
            
            if((situationSuggestionCapture.replace( /(<([^>]+)>)/ig, '')).replace(/\s/g, '').length == 0)
            	situationSuggestionCapture = (situationSuggestionCapture.replace(/(<([^>]+)>)/ig, '')).trim();
            if((ignoreSuggestionCapture.replace( /(<([^>]+)>)/ig, '')).replace(/\s/g, '').length == 0)
            	ignoreSuggestionCapture = (ignoreSuggestionCapture.replace(/(<([^>]+)>)/ig, '')).trim();
            
            instructionWrapper.handlerId = component.get('v.lFilteredSHMap')[0].SHMap.Handler__c;
            instructionWrapper.situationId = component.get('v.lFilteredSHMap')[0].SHMap.Situation__c;
            instructionWrapper.situationInstruction = situationSuggestionCapture;
            instructionWrapper.ignoreCondition = ignoreSuggestionCapture;
            instructionWrapperList.push(instructionWrapper);
            
            handlerCmp.updateMasterEdit(instructionWrapperList);
        }
    },
    
    cancelUpdateHandlers: function(component, event, helper) {
        component.set("v.displayMasterEdit",true);
        var handlerCmp = component.find('handlerCmpId');
        if(handlerCmp.length != undefined){
            for(var i = 0;i < handlerCmp.length;i++){
                let showEscalationList = false;
                let showIgnoreCondition = false;
                let handlerType = handlerCmp[i].get('v.HandlerDetails').Handler_Type__r.Name
                if(handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
                    showIgnoreCondition = "true";
                }
                if(handlerType == 'Attack Handler Type' ||handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
                    showEscalationList = "true";
                }
                handlerCmp[i].closeMasterEdit(showIgnoreCondition,showEscalationList);
            }
        }
        else{
            let showEscalationList = false;
            let showIgnoreCondition = false;
            let handlerType = handlerCmp.get('v.HandlerDetails').Handler_Type__r.Name
            if(handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
                showIgnoreCondition = "true";
            }
            if(handlerType == 'Attack Handler Type' ||handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
                showEscalationList = "true";
            }
            handlerCmp.closeMasterEdit(showIgnoreCondition,showEscalationList);
        }
    },
    
    printPage: function (component){
                //let activeSections = component.get("v.activeSections");
                let idArray = [];
                let result = component.get("v.ExistingSHMap");
                Object.keys(result).forEach(key => {
                    idArray.push(result[key].SHMap.Id);
                });
                    component.set("v.activeSections", idArray);
                    let urlText;
                    if(window.location.href.includes('/customers/'))
                    urlText = window.location.href.split('/s/')[0];
                    else if(window.location.href.includes('/lightning/'))
                    urlText = window.location.href.split('lightning/')[0];
                    component.set("v.activeSectionsOpenned",JSON.stringify(component.get('v.activeSections')))
                    component.set("v.isModalOpen", true);
                    let printPageURL = urlText+'/apex/SC_SOCC_PrintRunbook?recordId=' + component.get('v.recordId')+'&active='+component.get('v.activeSectionsOpenned')+'&isPrint=true';
                    component.set("v.vfURL",printPageURL);
                },
                    PDFPage: function (component){
                        //let activeSections = component.get("v.activeSections");
                        let idArray = [];
                        let result = component.get("v.ExistingSHMap");
                        Object.keys(result).forEach(key => {
                            idArray.push(result[key].SHMap.Id);
                        });
                            component.set("v.activeSections", idArray);
                            let urlText;
                            if(window.location.href.includes('/customers/'))
                            urlText = window.location.href.split('/s/')[0];
                            else if(window.location.href.includes('/lightning/'))
                            urlText = window.location.href.split('lightning/')[0];
                            component.set("v.activeSectionsOpenned",JSON.stringify(component.get('v.activeSections')))
                            component.set("v.isModalOpen", true);
                            let printPageURL = urlText+'/apex/SC_SOCC_PrintRunbook?recordId=' + component.get('v.recordId')+'&active='+component.get('v.activeSectionsOpenned')+'&isPrint=false';
                            component.set("v.vfURL",printPageURL);
                        },
    navigatetoHandler: function(component, event, helper) {
        var navService = component.find("navService");
        var pageReference = {    
            "type": "standard__navItemPage",
            "attributes": {
                "apiName": "Handler"    
            }
        }
        navService.navigate(pageReference);
    },

    dofilterInstruction: function(component) {
        component.find("childInstructions").searchInstructions(component.get("v.searchTermInstruction"));
    }
});