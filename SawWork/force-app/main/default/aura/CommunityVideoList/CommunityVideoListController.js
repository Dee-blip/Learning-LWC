({
	doInit: function(component,helper,event) {
        var action = component.get("c.fetchContentList");
        action.setParams({
            	topicId : component.get("v.topicId")
            });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    response.getReturnValue()[i].CreatedDate = response.getReturnValue()[i].CreatedDate.split('T')[0];
                }
                component.set("v.videoList", response.getReturnValue());
                if(response.getReturnValue().length == 0)
                {
                   	component.set("v.showNoRows", true);
                    component.set("v.showTable", false);
                }
                else
                {
                    component.set("v.showTable", true);
                    component.set("v.showSearch", true);
                }
            }
        });
        $A.enqueueAction(action);
    },
    playVideo: function(component, event, helper) {
        var videoId = event.getParam("videoId");
        var action = component.get("c.fetchdownLoadURL");
        action.setParams({
            	videoId : videoId
            });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                window.open(response.getReturnValue(),'_blank');
            }
        });
        $A.enqueueAction(action);
        
        //window.open(component.get("v.videoDownloadURL"),'_blank','height=200,width=200');
        //var videoId = event.getParam("videoId");
        var videoTitle = event.getParam("videoTitle");
        component.set("v.videoTitle", videoTitle);
        component.set("v.videoId", videoId);
        //component.set("v.isOpen", true);
        //component.set("v.isNewForm", true);
    },
    closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
    }
})