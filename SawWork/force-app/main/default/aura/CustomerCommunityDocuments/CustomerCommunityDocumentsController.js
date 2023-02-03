({
    doInit: function(component,event,helper) {
        helper.fetchNetworkId(component);//Added by Vikas for ESESP-1678
        helper.fetchDocumentList(component);
    },
    changeRecordNumber : function(component, event, helper) {
        var currentPagesCount  = component.find("selectItem").get("v.value");
        var dataCategoryId = component.get("v.documentGroupId");
        var action = component.get("c.fetchCommunityDocuments");
        action.setParams({
            "dataCategoryId" : dataCategoryId,
            "pageNumber" : component.get("v.pageNumber"),
            "currnetPagesCount" : currentPagesCount
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    var createdDate = response.getReturnValue()[i].communityDocument.CreatedDate;
                    var formattedDate = new Date(createdDate);
                    //formattedDate = formattedDate.toString().split(':')[0].slice(0,-3)
                    var ampm = formattedDate.getHours() >= 12 ? 'PM' : 'AM';
                    var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+((formattedDate.getHours() + 24) % 12 || 12) +':'+(formattedDate.getMinutes()<10?'0':'') + formattedDate.getMinutes()+' '+ampm;
                    response.getReturnValue()[i].communityDocument.CreatedDate = finalDate.slice(4);
                    //var userId = $A.get("$SObjectType.CurrentUser.Id");
                    //if((response.getReturnValue()[i].CreatedBy.Id).includes(userId))
                        //response.getReturnValue()[i].Edit_Document__c = true;
                }
                component.set("v.documentList", response.getReturnValue());
                helper.fetchPageCountAndTotal(component,currentPagesCount);
            }
        });
        $A.enqueueAction(action);

    },
    recordCounterChange : function(component, event, helper){
        var currnetPagesCount = event.getParam("currnetPagesCount");
        component.set("v.pageNumber", '1');
        component.set("v.currentPagesCount", currnetPagesCount);
        helper.getAllSobjectRecords(component,'1', currnetPagesCount);
    },
    
    searchDocument : function(component, event, helper){
        helper.seachDocumentList(component);
    },
    searchDocumentEnt : function(component, event, helper){
        if (event.getParams().keyCode === 13) {
            helper.seachDocumentList(component);
        }
    },
    goPreviousPage : function (component, event, helper) {
        var totalPages = component.get("v.pageCounterInfo.totalPages");
        var pageNumber = component.get("v.pageCounterInfo.currentPageNumber");
        var currnetPagesCount = component.find("selectItem").get("v.value");

        var dataCategoryId = component.get("v.documentGroupId");
        var action = component.get("c.fetchCommunityDocuments");
        action.setParams({
            "searchString" : component.get("v.searchKeyword"),
            "dataCategoryId" : dataCategoryId,
            //"pageNumber" : (parseInt(pageNumber)-1).toString(),
            "pageNumber" : "1",
            "currnetPagesCount" : currnetPagesCount.toString()
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    var createdDate = response.getReturnValue()[i].communityDocument.CreatedDate;
                    var formattedDate = new Date(createdDate);
                    //formattedDate = formattedDate.toString().split(':')[0].slice(0,-3)
                    var ampm = formattedDate.getHours() >= 12 ? 'PM' : 'AM';
                    var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+((formattedDate.getHours() + 24) % 12 || 12) +':'+(formattedDate.getMinutes()<10?'0':'') + formattedDate.getMinutes()+' '+ampm;
                    response.getReturnValue()[i].communityDocument.CreatedDate = finalDate.slice(4);
                    //var userId = $A.get("$SObjectType.CurrentUser.Id");
                    //if((response.getReturnValue()[i].CreatedBy.Id).includes(userId))
                        //response.getReturnValue()[i].Edit_Document__c = true;
                }
                component.set("v.documentList", response.getReturnValue());
                //helper.resetCounters(component, (parseInt(pageNumber)-1).toString(), currnetPagesCount,totalPages);
                helper.resetCounters(component, "1", currnetPagesCount,totalPages);
            }
        });
        $A.enqueueAction(action);
    },

    goNextPage : function (component, event, helper) {
        var totalPages = component.get("v.pageCounterInfo.totalPages");
        var pageNumber = component.get("v.pageCounterInfo.currentPageNumber");
        var currnetPagesCount = component.find("selectItem").get("v.value");

        var dataCategoryId = component.get("v.documentGroupId");
        var action = component.get("c.fetchCommunityDocuments");
        action.setParams({
            "searchString" : component.get("v.searchKeyword"),
            "dataCategoryId" : dataCategoryId,
            //"pageNumber" : (parseInt(pageNumber)+1).toString(),
            "pageNumber" : totalPages.toString(),
            "currnetPagesCount" : currnetPagesCount.toString()
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                 for (var i = 0; i < response.getReturnValue().length; i++) {
                    var createdDate = response.getReturnValue()[i].communityDocument.CreatedDate;
                    var formattedDate = new Date(createdDate);
                    //formattedDate = formattedDate.toString().split(':')[0].slice(0,-3)
                    var ampm = formattedDate.getHours() >= 12 ? 'PM' : 'AM';
                    var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+((formattedDate.getHours() + 24) % 12 || 12) +':'+(formattedDate.getMinutes()<10?'0':'') + formattedDate.getMinutes()+' '+ampm;
                    response.getReturnValue()[i].communityDocument.CreatedDate = finalDate.slice(4);
                    //var userId = $A.get("$SObjectType.CurrentUser.Id");
                    //if((response.getReturnValue()[i].CreatedBy.Id).includes(userId))
                        //response.getReturnValue()[i].Edit_Document__c = true;
                }
                component.set("v.documentList", response.getReturnValue());
                //helper.resetCounters(component, (parseInt(pageNumber)+1).toString(), currnetPagesCount,totalPages);
                helper.resetCounters(component, totalPages.toString(), currnetPagesCount,totalPages);
            }
        });
        $A.enqueueAction(action);
    },

    pageChange: function (component, event, helper) {
        var pageNumber = event.getParam("pageNumber");
        var currnetPagesCount = component.find("selectItem").get("v.value");
        var totalPages = component.get("v.pageCounterInfo.totalPages");
        var dataCategoryId = component.get("v.documentGroupId");
                
        var action = component.get("c.fetchCommunityDocuments");
        action.setParams({
            "searchString" : component.get("v.searchKeyword"),
            "dataCategoryId" : dataCategoryId,
            "pageNumber" : (parseInt(pageNumber)).toString(),
            "currnetPagesCount" : currnetPagesCount.toString()
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    var createdDate = response.getReturnValue()[i].communityDocument.CreatedDate;
                    var formattedDate = new Date(createdDate);
                    //formattedDate = formattedDate.toString().split(':')[0].slice(0,-3)
                    var ampm = formattedDate.getHours() >= 12 ? 'PM' : 'AM';
                    var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+((formattedDate.getHours() + 24) % 12 || 12) +':'+(formattedDate.getMinutes()<10?'0':'') + formattedDate.getMinutes()+' '+ampm;
                    response.getReturnValue()[i].communityDocument.CreatedDate = finalDate.slice(4);
                    //var userId = $A.get("$SObjectType.CurrentUser.Id");
                    //if((response.getReturnValue()[i].CreatedBy.Id).includes(userId))
                        //response.getReturnValue()[i].Edit_Document__c = true;
                }
                component.set("v.documentList", response.getReturnValue());
                helper.resetCounters(component, pageNumber, currnetPagesCount,totalPages);
            }
        });
        $A.enqueueAction(action);
    },
    editDocument: function (component, event, helper) {
        var action = component.get("c.fetchDocument");
        action.setParams({
            documentId : event.target.id
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                component.set("v.doc", a.getReturnValue());
                component.set("v.showDocumentEdit", true);
                component.set("v.isEdit", true);
                component.set("v.isDelete", false);
                component.set("v.isEditForm", true);
                component.set("v.isDeleteForm", false);
                component.set("v.isConfirmSave", true);
                component.set("v.isConfirmDelete", false);
            } else if(state == "ERROR"){
                //alert('Error in calling server side action');
                alert($A.get('$Label.c.Jarvis_CustomerCommunityDocuments_ServerSideError')); // eslint-disable-line no-alert
            }
        });
        $A.enqueueAction(action);
    },
    showDelForm: function (component, event, helper) {
        component.set("v.delDocRec", event.target.id);
        component.set("v.showDocumentEdit", true);
        component.set("v.isEdit", false);
        component.set("v.isDelete", true);
        component.set("v.isEditForm", false);
        component.set("v.isDeleteForm", true);
        component.set("v.isConfirmSave", false);
        component.set("v.isConfirmDelete", true);
    },
    delDocument: function (component, event, helper) {
        var doc = component.get("v.delDocRec");
        var action = component.get("c.delDoc");
        action.setParams({
            documentId : doc
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                component.set("v.showDocumentEdit", false);
                setTimeout(
                    function() 
                    { 
                        $A.get('e.force:refreshView').fire(); 
                        window.open(window.location.href,'_top');
                    }, 1000);
            } else if(state == "ERROR"){
                //alert('Error in calling server side action');
                alert($A.get('$Label.c.Jarvis_CustomerCommunityDocuments_ServerSideError')); // eslint-disable-line no-alert
            }
        });
        $A.enqueueAction(action);
    },
    saveDocument: function (component, event, helper) {
        var doc = component.get("v.doc");
        var action = component.get("c.saveDoc");
        let url = '/customers/s/customer-community-document/';
        action.setParams({
            documentRecord : doc
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                if(a.getReturnValue() != null && a.getReturnValue().indexOf('SIZEERROR')==0){
                    //alert('Document Description('+a.getReturnValue().substr(9)+' characters) exceeded maximum character(131072 characters) limit. Please reduce the size and save.');
                    alert($A.get('$Label.c.Jarvis_CustomerCommunityDocuments_DescriptionTooLongError')); // eslint-disable-line no-alert
                }
                else{
                    component.set("v.showDocumentEdit", false);
                    url = url+a.getReturnValue();
                    setTimeout(
                        function() 
                        { 
                            //$A.get('e.force:refreshView').fire(); 
                            //window.open(window.location.href,'_top');
                            window.location=url;
                        }, 1000);
                }
            } else if(state == "ERROR"){
                //alert('Error in calling server side action');
                alert($A.get('$Label.c.Jarvis_CustomerCommunityDocuments_ServerSideError')); // eslint-disable-line no-alert
            }
        });
        $A.enqueueAction(action);
    },
    closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.showDocumentEdit", false);
    },
})