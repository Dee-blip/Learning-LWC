({
    doInit: function(component,event,helper) {
        helper.fetchBlogList(component);
    },
    changeRecordNumber : function(component, event, helper) {
        var currentPagesCount  = component.find("selectItem").get("v.value");
        var dataCategoryId = component.get("v.blogListTopicId");
        var action = component.get("c.fetchCommunityBlogs");
        action.setParams({
            "dataCategoryId" : dataCategoryId,
            "pageNumber" : component.get("v.pageNumber"),
            "currnetPagesCount" : currentPagesCount
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
    searchBlogs : function(component, event, helper){
        helper.seachBlogList(component);
    },
    searchBlogsEnt: function(component, event, helper){
        if (event.getParams().keyCode === 13) {
            helper.seachBlogList(component);
        }
    },
	goPreviousPage : function (component, event, helper) {
        var totalPages = component.get("v.pageCounterInfo.totalPages");
        var pageNumber = component.get("v.pageCounterInfo.currentPageNumber");
        var currnetPagesCount = component.find("selectItem").get("v.value");

        var dataCategoryId = component.get("v.blogListTopicId");
        var action = component.get("c.fetchCommunityBlogs");
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

        var dataCategoryId = component.get("v.blogListTopicId");
        var action = component.get("c.fetchCommunityBlogs");
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
                //helper.resetCounters(component, (parseInt(pageNumber)+1).toString(), currnetPagesCount,totalPages);
                helper.resetCounters(component, totalPages, currnetPagesCount,totalPages);
            }
        });
        $A.enqueueAction(action);
    },

    pageChange: function (component, event, helper) {
        
        var pageNumber = event.getParam("pageNumber");
        var currnetPagesCount = component.find("selectItem").get("v.value");
        var totalPages = component.get("v.pageCounterInfo.totalPages");
        var dataCategoryId = component.get("v.blogListTopicId");
                
        var action = component.get("c.fetchCommunityBlogs");
        action.setParams({
            "searchString" : component.get("v.searchKeyword"),
            "dataCategoryId" : dataCategoryId,
            "pageNumber" : (parseInt(pageNumber)).toString(),
            "currnetPagesCount" : currnetPagesCount.toString()
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
                helper.resetCounters(component, pageNumber, currnetPagesCount,totalPages);
            }
        });
        $A.enqueueAction(action);
    },
    /*search: function (component, event, helper) {
        helper.seachBlogList(component,event,helper);
    	if(event.keyCode == 13){
           var searchString = component.find('searchId').get('v.value');
        }
    }*/
})