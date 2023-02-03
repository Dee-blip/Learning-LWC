({
   doInit : function(component, event, helper) {
       
       window.addEventListener('resize', $A.getCallback(
           function(){
               if(component.isValid()) {
                   helper.resize(component,event,helper);
               }
			}
       ));
    },
    
    scriptsLoaded : function(component, event, helper) {
         
      jQuery("document").ready(function(){
          console.log('scripts loaded');
          var navigationItemsJson = JSON.parse(sessionStorage.getItem('partnernavigation--records'));
          if (navigationItemsJson != null) {
              console.log('Navigation from cache');
              component.set("v.menuItems", navigationItemsJson);
             // helper.resize(component,event,helper); // commented SFDC 8015
          } else {
              helper.serverSideCall(component,event,helper,"c.getNavigationItems").then(
                  function(response) {
                      console.log('SH : conditions - response :'+response);
                      if (response != null) {
                          console.log(response);
                          // Set the 'menuItems' variable back in the component.
                          sessionStorage.setItem('partnernavigation--records', JSON.stringify(response));
                          component.set("v.menuItems", response);
                          helper.resize(component,event,helper);
                      }
                  }
              ).catch(
                  function(error) {
                      component.set("v.status" ,error ); 
                      console.log(error);
                  }
              );
          }
          window.setTimeout(helper.resize, 100, component, event, helper); // SFDC 8015

      });
        
 	},
    
    onClick : function(component, event, helper) {
       console.log('Li clicked');
        console.log(event.target);
       var value = event.currentTarget.dataset.value;
        console.log('id :'+value);
        helper.serverSideCall(component,event,helper,"c.getNavigationUrl",{navigationMenuId:value}).then(
            function(response) {
                console.log('SH : conditions - response :'+response);
                if (response != null) {
                    var urlVal = response;
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": urlVal
                    });
                    urlEvent.fire();
                }
            }
        ).catch(
            function(error) {
                console.log(error);
            }
        );  
     }
})