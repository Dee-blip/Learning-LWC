({
    onInit : function(component, event, helper) {
        var url = $A.get('$Resource.AMI_Akamai_logo');
        component.set('v.backgroundImageURL', url);
    }
})