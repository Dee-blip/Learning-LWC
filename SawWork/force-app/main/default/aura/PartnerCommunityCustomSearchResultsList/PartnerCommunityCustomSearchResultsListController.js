({
    init: function(component, event, helper) {
        
        // check if there is search text in the url
        var completeUrl = window.location.href;
        var searchText = completeUrl.replace(/.*searchText=([^&]*).*|(.*)/, '$1');
        console.log('Search text');
        console.log(searchText);
        var objJson;
        
        if (searchText) {
            searchText = searchText.replace("+", " ");
            component.set('v.loaded', !component.get('v.loaded'));
            helper.serverSideCall(component,event,helper,"c.searchForRecords",{searchText: searchText}).then(
                function(response) {
                    console.log('SH : search');
                    console.log(response);
                    if (response != null) {
                        objJson = response;
                        console.log('Result');
                        console.log(objJson);
                        helper.populateRecords(component,event,helper,objJson);
                        component.set('v.loaded', !component.get('v.loaded'));
                    }
                }
            ).catch(
                function(error) {
                    component.set("v.status" ,error );
                    component.set('v.loaded', !component.get('v.loaded'));
                    console.log(error);
                }
            );
        } else {
            objJson = sessionStorage.getItem('customSearch--records'); 
            helper.populateRecords(component,event,helper,objJson);
        }
        
	},
    
    handleTabClickJS: function(component, event, helper) {
        console.log('Inside tab clicked');
        var value = event.currentTarget.dataset.value;
        console.log('id :'+value);
        
        var objectList = [];
        var newObjectList = [];
        objectList = component.get('v.objectList');
        console.log('Existing object list');
        console.log(objectList);
        objectList.forEach((item) => {
            console.log(item);
            console.log('item.key : '+item.key + '   ::: value : '+value);
            if (item.key===value) {
            console.log('Adding as active');
            item.active = true;
            //newObjectList.push({value:item.value, key:item.key, active:true});
            newObjectList.push(item);
            console.log('Added as active');
        } else {
            console.log('Adding as inactive');
            item.active = false;
            //newObjectList.push({value:response[key], key:key, active:false});
            newObjectList.push(item);
            console.log('Added as in-active');
        }
        });
            console.log('Updated object ');
            console.log(newObjectList);
            component.set('v.objectList',newObjectList);
        }
})