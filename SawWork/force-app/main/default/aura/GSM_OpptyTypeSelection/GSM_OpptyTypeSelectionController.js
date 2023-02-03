({
    handleBaselineChange : function(component, event, helper) {
        var opptyBaslinePicked = event.getParam("selection");
        var withBaseLineType = "Create Opportunity with Contract Baseline";
        var withContractChange = "Create Contract Change Opportunity";
        if(opptyBaslinePicked == withBaseLineType || opptyBaslinePicked == withContractChange){
            component.set("v.doneLoading",false);
        }else{
            component.set("v.doneLoading",true);
        }
        if(opptyBaslinePicked == withContractChange){
            component.set("v.isContractChange",true);
        }
        else{
            component.set("v.isContractChange",false);
        }
    },
    handleContractChange : function(component, event, helper) {
        var contractIds = event.getParam("contracts");
        if(contractIds && contractIds.length>0){
            component.set("v.doneLoading",true);
        }else{
            component.set("v.doneLoading",false);
        }
    },
    typeChange : function(component, event, helper) {
        var appEvent = $A.get("e.c:GSM_OpptyTypeChangeEvt");
        appEvent.setParams({ "opptyType" : event.getSource().get("v.value") });
        appEvent.fire();
    },
    handleAccountChange : function(component, event, helper) {
        component.set("v.doneLoading",false);
    },
    handleBaselineChangeMobile : function(component, event, helper) {
        component.set("v.doneLoading",event.getParam("showWithoutContractBL") | event.getParam("showCurrencySelection"));
    }
})