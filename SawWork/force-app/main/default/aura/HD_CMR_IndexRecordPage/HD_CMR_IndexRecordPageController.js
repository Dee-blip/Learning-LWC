({

    doInit : function(component,event, helper){

        helper.getListViews(component,event);
        helper.getUserConfiguration(component,event);
        helper.setUserType(component,event);

    },


    refreshView : function(component,event, helper){
        if (event !== null && typeof event.getParam === 'function' && event.getParam("quickAction") && event.getParam("quickAction") !== 'updateRecords') {
            return;
        }
        helper.getRecords(component,event);
    },


    showPreview : function(component,event,helper){

        component.set("v.selectedRecord",event.getParam("record"));
        component.set("v.records",component.get("v.records"));

        var recordFromEvent  = event.getParam("record");
        var record = component.get("v.selectedRecord");

        component.set("v.show_preview",false);
        component.set("v.show_preview",event.getParam("show-hide"));

    },

    hideOrShowCustomColumnsForm :function(component, event, helper){

        var action = component.get("c.getColumns");
        action.setCallback(this,function(response){
          var data = response.getReturnValue(response);
            if(response.getState()==="SUCCESS"){

                component.set("v.colMap",data);
                component.set("v.renderCustomColumnsForm",event.getParam("renderCustomizeForm"));
            }else if(response.getState() === "ERROR"){
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }


        });
        $A.enqueueAction(action);
    },


    updateUserColumns:function(component,event,helper){

        var config = event.getParam("finalColumnsLabel");
        var action = component.get("c.updateSelectedColumns");

        action.setParams({selectedColumns:config});
        action.setCallback(this,function(response){
          var data = response.getReturnValue(response);
            if(response.getState()==="SUCCESS"){

                component.set("v.colApis",event.getParam("finalColumnsAPI"));

                var apis = event.getParam("finalColumnsAPI");
            	var cols = apis.map(ap => config[ap]);

            	component.set("v.colLabels",cols);
            	component.set("v.defaultOptions",apis);

            	helper.getRecords(component,event);
            }else if(response.getState() === "ERROR"){
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }

        });
        $A.enqueueAction(action);

    }
})