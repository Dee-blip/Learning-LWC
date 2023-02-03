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
            dataCategoryId : component.get("v.blogListTopicId"),
            "searchString" : component.get("v.searchKeyword"),
            "pageNumber" : component.get("v.pageNumber"),
            "currnetPagesCount" : component.get("v.currentPagesCount")
        });

        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.pageCounterInfo", response.getReturnValue()); 
            }
        });
        $A.enqueueAction(action1);
	},
    fetchBlogList : function(component,event,helper) {
        var dataCategoryId = component.get("v.blogListTopicId");
        var action = component.get("c.fetchCommunityBlogs");
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
                for (var i = 0; i < response.getReturnValue().allBlogList.length; i++) {
                    if(response.getReturnValue().allBlogList[i].Community_Blog_AKAM_Created_Date__c != null)
                    {
                        var createdDate = response.getReturnValue().allBlogList[i].Community_Blog_AKAM_Created_Date__c;
                        var formattedDate = new Date(createdDate);
                        //formattedDate = formattedDate.toString().split(':')[0].slice(0,-3)
                        var ampm = formattedDate.getHours() >= 12 ? 'PM' : 'AM';
                        var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+((formattedDate.getHours() + 24) % 12 || 12) +':'+(formattedDate.getMinutes()<10?'0':'') + formattedDate.getMinutes()+' '+ampm;
                        response.getReturnValue().allBlogList[i].Community_Blog_AKAM_Created_Date__c = finalDate.slice(4);
                    }
                }
                component.set("v.blogList", response.getReturnValue().allBlogList);
                component.set("v.totalBlogs",response.getReturnValue().totalRecords);
                if(response.getReturnValue().totalRecords == 0)
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
    seachBlogList: function(component,event,helper) {
        var action = component.get("c.fetchCommunityBlogs");
        var self = this;
        action.setParams({
            "searchString" : component.get("v.searchKeyword"),
            "dataCategoryId" : component.get("v.blogListTopicId"),
            "pageNumber" : component.get("v.pageNumber"),
            "currnetPagesCount" : component.get("v.currentPagesCount")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().allBlogList.length; i++) {
                    if(response.getReturnValue().allBlogList[i].Community_Blog_AKAM_Created_Date__c != null)
                    {
                        var createdDate = response.getReturnValue().allBlogList[i].Community_Blog_AKAM_Created_Date__c;
                        var formattedDate = new Date(createdDate);
                        //formattedDate = formattedDate.toString().split(':')[0].slice(0,-3)
                        var ampm = formattedDate.getHours() >= 12 ? 'PM' : 'AM';
                        var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+((formattedDate.getHours() + 24) % 12 || 12) +':'+(formattedDate.getMinutes()<10?'0':'') + formattedDate.getMinutes()+' '+ampm;
                        response.getReturnValue().allBlogList[i].Community_Blog_AKAM_Created_Date__c = finalDate.slice(4);
                    }
                }
                component.set("v.blogList", response.getReturnValue().allBlogList);
                component.set("v.totalBlogs",response.getReturnValue().totalRecords);
                if(response.getReturnValue().totalRecords == 0)
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