({
    handleDoInit : function(cmp, event) {
        console.log('In HelperdoInt');
    },
    
    handleOnSave : function(cmp, event){

       var userRec = cmp.get("{!v.userRec}") !== null ? cmp.get("{!v.userRec}").val : null;
        var recordTyp = cmp.get('v.recordTypeName') !== '--None--' ? cmp.get("v.recordTypeName"): null;
        var recs = cmp.get('v.records');
        var regions = [];
        for(var i in recs){
                if(recs[i]["type"] && recs[i]["value"] && recs[i]["value"]["val"]){
                    regions.push({'type':recs[i]["type"], 'id':recs[i]["value"]["val"]});
                }
            }
        //console.log(' User is not present ::::::' + userRec);
        if(cmp.get("v.userRec") && regions.length >= 1 && recordTyp != null){
            var recs = cmp.get('v.records');
            var regions = [];
            for(var i in recs){
                if(recs[i]["type"] && recs[i]["value"] && recs[i]["value"]["val"]){
                    regions.push({'type':recs[i]["type"], 'id':recs[i]["value"]["val"]});
                }
            }
            debugger;
            console.log('user : ' + cmp.get("v.userRec.val"));
            var paramsObj = { 'user': cmp.get("v.userRec.val"), 'regions': regions, 'recordType': recordTyp };
            var params = JSON.stringify(paramsObj);
            console.log('params : ' + params);
            var action = cmp.get("c.createNewUserRegion");
            action.setParams({
                params
            });
            action.setCallback(this,function(res) {
            var state = res.getState();
            console.log('state ::::::::'+ state);
            if(state == 'SUCCESS') {
                var result = res.getReturnValue();
                //alert('result ::' + result);
                if(result =='Success'){
                    this.handleOnClose(cmp);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    title : 'Info Message',
                    message: 'Saved',
                    messageTemplate: 'Saved',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'success',
                    mode: 'dismissible'
                    });
                    toastEvent.fire();
                }
                else if(result !== 'Success'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    title : 'Error Message',
                    message: result,
                    messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
                    
                }
                
            }
            else {
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    title : 'Error Message',
                    message: 'Failed due to unknown error',
                    messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
        }
        else if(!userRec || userRec == null){
            var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error Message',
                    message:'User is required to create a User to Region Map',
                    messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
        }
        else if (regions === undefined || regions.length == 0) {
            var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error Message',
                    message:'Any of DGRAT value is required to create User to Region Map',
                    messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();  
        }
    },
    
    handleOnClose:function(component, event) {
        var recId = component.get("v.recordId");
        if (!recId) {
            var homeEvt = $A.get("e.force:navigateToObjectHome");
            homeEvt.setParams({
                "scope": "Inv_WorkBox_Region_Mapping__c"
            });
            homeEvt.fire();
        } else {
            helper.navigateTo(component, recId);
        }
    }

                
})