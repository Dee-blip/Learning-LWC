({
	serverSideCall : function(component,event,helper,method,params) {
        return new Promise(function(resolve, reject) {
            console.log('SH : Helper from parent component');
            console.log('Adding spinner')
            //var spinner = helper.asArray(component.find("pageSpinner"));
            var spinner = component.find("pageSpinner");
        	$A.util.toggleClass(spinner, "slds-hide");
            var action = component.get(method);
        	if(params){
            	action.setParams(params);
        	}
            action.setCallback(this, 
                               function(response) {
                                   console.log('Removing spinner');
                                   $A.util.toggleClass(spinner, "slds-hide");
                                   var state = response.getState();
                                   if (state === "SUCCESS") {
                                       resolve(response.getReturnValue());
                                   } else {
                                       reject(response.getError());
                                   }
                               });
            $A.enqueueAction(action);
        });
    },
    
    resize : function(component, event, helper,menu,maxHeight) {
        console.log('resizing now');
        var menu = '#nav';
        var maxHeight = 50;
        var nav = $(menu);
		var navHeight = nav.innerHeight();
        console.log('navHeight :'+navHeight);
        if (navHeight >= maxHeight) {
            
            $(menu + ' .dropdown').removeClass('d-none');
            $(".navbar-nav").removeClass('w-auto').addClass("w-100");
            
            while (navHeight > maxHeight) {
                //  add child to dropdown
                var children = nav.children(menu + ' li:not(:last-child)');
                var count = children.length;
                $(children[count - 1]).prependTo(menu + ' .dropdown-menu');
                navHeight = nav.innerHeight();
            }
            $(".navbar-nav").addClass("w-auto").removeClass('w-100');
        }
        else {
            
            var collapsed = $(menu + ' .dropdown-menu').children(menu + ' li');
          
            if (collapsed.length===0) {
              $(menu + ' .dropdown').addClass('d-none');
            }
          
            while (navHeight < maxHeight && (nav.children(menu + ' li').length > 0) && collapsed.length > 0) {
                //  remove child from dropdown
                collapsed = $(menu + ' .dropdown-menu').children('li');
                $(collapsed[0]).insertBefore(nav.children(menu + ' li:last-child'));
                navHeight = nav.innerHeight();
            }
    
            if (navHeight > maxHeight) { 
                helper.resize(component,event,helper,menu,maxHeight);
            }
            
        }
 	},
})