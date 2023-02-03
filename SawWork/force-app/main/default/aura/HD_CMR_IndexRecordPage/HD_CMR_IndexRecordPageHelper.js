({
    getListViews : function(component,event) {

        var listViewAction = component.get("c.getAllListViews");
        listViewAction.setStorable();
        listViewAction.setCallback(this,function(response){
          var data = response.getReturnValue(response);
            if(response.getState() === "SUCCESS"){

            	component.set("v.listViewOptions",data);
            }else if(response.getState() === "ERROR"){
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }

        });
        $A.enqueueAction(listViewAction);
    },


    getUserConfiguration: function(component,event){
        var action = component.get("c.getUserColumns");
        action.setCallback(this,function(response){
          var data = response.getReturnValue(response);
            if(response.getState() === "SUCCESS"){

                var colLables = [];
                var colApis = [];
                for(var property in data){

                    colApis.push(property);
                    colLables.push(data[property]);
                }

                component.set("v.colLabels",colLables);
                component.set("v.colApis",colApis);
                component.set("v.defaultOptions",colApis);
            }else if(response.getState() === "ERROR"){
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }


        })
        $A.enqueueAction(action);
    },

    getRecords : function(cmp,event) {
        console.log("get data "+event.getParam("searchVal"));

        var action = cmp.get('c.getChangeList');

        //action.setStorable();
		console.log(event.getParams());
        action.setParams({
            filterId: event.getParam("fltrId")  || cmp.get("v.fltrId"),
            noOfRecs: event.getParam("numRecords")  || cmp.get("v.numRecords"),
            ticketNumber: event.getParam("searchVal") || null,
            pageNo: event.getParam("pageNum") || cmp.get("v.pageNum"),
            orderBy: event.getParam("sortBy") || cmp.get("v.sortBy") ,
            sortDirection: event.getParam("sortDirection") || cmp.get("v.sortDirection")
        });

        cmp.set("v.loading",true);
        action.setCallback(this,function (response) {

            cmp.set("v.loading",false);
            var state = response.getState();
            var data = response.getReturnValue(response);
            if (state === "SUCCESS") {


                cmp.set("v.sortBy",event.getParam("sortBy")||cmp.get("v.sortBy"));
                cmp.set("v.sortDirection",event.getParam("sortDirection") || cmp.get("v.sortDirection"));
                cmp.set("v.fltrId",event.getParam("fltrId") || cmp.get("v.fltrId"));
                cmp.set("v.numRecords",event.getParam("numRecords") || cmp.get("v.numRecords"));
                cmp.set("v.pageNum",event.getParam("pageNum") || cmp.get("v.pageNum"));

                cmp.set("v.records",response.getReturnValue().records);
                cmp.set("v.noOfPages",response.getReturnValue().noOfPages);
                cmp.set("v.noOfRecords",response.getReturnValue().noOfRecords);
                if(cmp.get("v.noOfRecords") == 0){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Warning Message',
                        message:'No records found',
                        messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'warning',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                }



            } else if (state === "ERROR") {
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }


        });
        $A.enqueueAction(action);
    },

    /*getData  : function(cmp,event){

        var action = cmp.get('c.getChangeList');

        action.setParams({
            filterId: event.getParam("fltrId")  || cmp.get("v.fltrId"),
            noOfRecs: event.getParam("numRecords")  || cmp.get("v.numRecords"),
            ticketNumber: null,
            pageNo: event.getParam("pageNum") || cmp.get("v.pageNum"),
            orderBy: event.getParam("sortBy") || cmp.get("v.sortBy") ,
            sortDirection: event.getParam("sortDirection") || cmp.get("v.sortDirection")
        });


        action.setCallback(this,function (response) {
            cmp.set("v.loading",false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('records');
                console.log(response.getReturnValue().records);

                cmp.set("v.records",response.getReturnValue().records);
                cmp.set("v.noOfPages",response.getReturnValue().noOfPages);
                cmp.set("v.noOfRecords",response.getReturnValue().noOfRecords);


            } else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }

        });
        $A.enqueueAction(action);
		cmp.set("v.loading",true);
    }*/
    
    
    setUserType: function(component,event,helper){
        var action = component.get("c.getUserType"); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            var resp = response.getReturnValue();
            if(component.isValid() && state === "SUCCESS"){
                if(resp != null && resp != ''){
                    if( resp.includes('CAB')){
                        component.set("v.isCABManager",true);
                    }
                }
            }else if(state === "ERROR"){
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }

        }); 
        $A.enqueueAction(action);                    
    }, 
})