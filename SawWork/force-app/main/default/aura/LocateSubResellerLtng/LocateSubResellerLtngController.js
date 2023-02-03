({
doInit: function(component, event, helper) {
        component.set("v.pageUtil.isloadDisabled",false); 
        component.set("v.clientWarError",$A.get("$Label.c.Account_Sub_Reseller_client_war_err_info").split('#'));
        helper.getColumn(component, event, helper);
        helper.intialiZeData(component,event,helper,false);
},
handleMore: function(component, event, helper) {
        component.set('v.loadMoreStatus', 'Loading....');
        component.set("v.pageUtil.spinner",true);
        helper.getMoreAccount(component, component.get('v.rowsToLoad')).then($A.getCallback(function(data) {
             if (component.get('v.data').length >= component.get('v.totalNumberOfRows')) 
             {
               component.set("v.pageUtil.isloadDisabled",true);  
               component.set('v.loadMoreStatus', component.get("v.clientWarError")[2]);
               component.set("v.pageUtil.spinner",false);
             } 
             else {
                 var currentData = component.get('v.data');
                 var newData = currentData.concat(helper.prasetoLdcompatible(component,data.accList,"Account"));
                 component.set('v.data', newData);
                 component.set('v.loadMoreStatus', component.get("v.clientWarError")[3]);
                 component.set("v.pageUtil.spinner",false);
                } 
               
          }));
     },

handleRowAction: function(cmp, event, helper) {
        var row = event.getParam('row');
        var accountId = row.Id;
        helper.updateReseller(cmp, event, helper, accountId);
    },
onBack: function(component, event, helper) {
         helper.navigatetoURL(component,event,helper,component.get("v.recordId")); 
         
    },

onSearch: function(component, event, helper) {
            component.set("v.pageUtil.isMessageVisible"),false
            helper.resetData(component,event,helper);
            helper.intialiZeData(component,event,helper,true);
             
        },
onChange : function(component,event,helper){
            var isMissing  = helper.checkfieldValidity(component,event,helper,component.find("searchSrname"),3);
            isMissing == true ? component.set("v.pageUtil.searchDisabled",true) : (component.set("v.pageUtil.searchDisabled",false),component.set("v.pageUtil.isMessageVisible"),false);
     },
onKeyup : function(component,event,helper)
    {
        var isMissing  = helper.checkfieldValidity(component,event,helper,component.find("searchSrname"),3);
        if(!isMissing && event.keyCode ===13)
        {
            component.set("v.pageUtil.isMessageVisible"),false
            helper.resetData(component,event,helper);
            helper.intialiZeData(component,event,helper,true);
        }

    }
})