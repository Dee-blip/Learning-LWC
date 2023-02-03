({
	getAllSobjectRecords : function(component,pNum,rCunt) {
		var action = component.get("c.getAllRecords");
		action.setParams({
            "pageNumber" : pNum.toString(),
            "currnetPagesCount" : rCunt.toString()
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.accounts", response.getReturnValue());                
            }
        });
        $A.enqueueAction(action);	
	},
    
    fetchPageCountAndTotal : function(component,rCount) {
		var action1 = component.get("c.getPageCountInfo");
        action1.setParams({
            "pageCountInfo" : rCount,
            "dataCategoryId" : component.get("v.documentGroupId"),
            "searchString" : component.get("v.searchKeyword"),
            "pageNumber" : component.get("v.pageNumber"),
            "currnetPagesCount" : component.get("v.currentPagesCount")
        });

        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.pageCounterInfo", response.getReturnValue()); 
                //return false;
            }
        });
        $A.enqueueAction(action1);
	},
    
    fetchDocumentList : function(component,event,helper) {
        var dataCategoryId = component.get("v.documentGroupId");
        var action = component.get("c.fetchCommunityDocuments");
        var self = this;
        //Setting the Apex Parameter
        action.setParams({
            "searchString" : component.get("v.searchKeyword"),
            "dataCategoryId" : dataCategoryId,
            "pageNumber" : component.get("v.pageNumber"),
            "currnetPagesCount" : component.get("v.currentPagesCount")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.totalDocuments",0);
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    var createdDate = response.getReturnValue()[i].communityDocument.CreatedDate;
                    var formattedDate = new Date(createdDate);
                    //formattedDate = formattedDate.toString().split(':')[0].slice(0,-3)
                    var ampm = formattedDate.getHours() >= 12 ? 'PM' : 'AM';
                    var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+((formattedDate.getHours() + 24) % 12 || 12) +':'+(formattedDate.getMinutes()<10?'0':'') + formattedDate.getMinutes()+' '+ampm;
                    response.getReturnValue()[i].communityDocument.CreatedDate = finalDate.slice(4);
                	component.set("v.totalDocuments",response.getReturnValue()[0].totalRecords);
                    //var userId = $A.get("$SObjectType.CurrentUser.Id");
                    //if((response.getReturnValue()[i].CreatedBy.Id).includes(userId))
                        //response.getReturnValue()[i].Edit_Document__c = true;
                }
                component.set("v.documentList", response.getReturnValue());
               
                if(response.getReturnValue().length == 0)
                {
                   	component.set("v.showNoRows", true);
                    component.set("v.showTable", false);
                    component.set("v.showSearch", false);
                }
                else
                {
                    component.set("v.showTable", true);
                    component.set("v.showSearch", true);
                    component.set("v.showNoRows", false);
                }   
            }
            self.fetchPageCountAndTotal(component,'');
        });
        $A.enqueueAction(action);
	},
    //Added by Vikas for ESESP-1678
    fetchNetworkId: function(component){
        var networkIdAction = component.get("c.fetchCommunityId");
        networkIdAction.setCallback(this, function(response){
            component.set("v.communityId",response.getReturnValue());
        });
        $A.enqueueAction(networkIdAction);
    },
    seachDocumentList: function(component,event,helper) {
        var action = component.get("c.fetchCommunityDocuments");
        var self = this;
        action.setParams({
            "searchString" : component.get("v.searchKeyword"),
            "dataCategoryId" : component.get("v.documentGroupId"),
            "pageNumber" : component.get("v.pageNumber"),
            "currnetPagesCount" : component.get("v.currentPagesCount")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.totalDocuments",0);
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    var createdDate = response.getReturnValue()[i].communityDocument.CreatedDate;
                    var formattedDate = new Date(createdDate);
                    //formattedDate = formattedDate.toString().split(':')[0].slice(0,-3)
                    var ampm = formattedDate.getHours() >= 12 ? 'PM' : 'AM';
                    var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+((formattedDate.getHours() + 24) % 12 || 12) +':'+(formattedDate.getMinutes()<10?'0':'') + formattedDate.getMinutes()+' '+ampm;
                    response.getReturnValue()[i].communityDocument.CreatedDate = finalDate.slice(4);
                    component.set("v.totalDocuments",response.getReturnValue()[i].totalRecords);
                    //var userId = $A.get("$SObjectType.CurrentUser.Id");
                    //if((response.getReturnValue()[i].CreatedBy.Id).includes(userId))
                        //response.getReturnValue()[i].Edit_Document__c = true;
                }
                component.set("v.documentList", response.getReturnValue());
                
                //component.set("v.totalDocuments",response.getReturnValue()[0].totalRecords);
                if(response.getReturnValue().length == 0)
                {
                   	component.set("v.showNoRows", true);
                    component.set("v.showTable", false);
                    component.set("v.showSearch", true);
                }
                else
                {
                    component.set("v.showTable", true);
                    component.set("v.showSearch", true);
                    component.set("v.showNoRows", false);
                } 
            }
            self.fetchPageCountAndTotal(component,'');
        });
        //$A.get('e.force:refreshView').fire();
        $A.enqueueAction(action);
    },
    
    resetCounters : function (component,pNum,rCunt,totalPage) {
        var action = component.get("c.getPageCountChange");
	    action.setParams({
            "pageNumber" : pNum.toString(),
            "currnetPagesCount" : rCunt.toString(),
            "totalPages" : totalPage.toString()
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                console.log(response.getReturnValue());
                component.set("v.pageCounterInfo", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})