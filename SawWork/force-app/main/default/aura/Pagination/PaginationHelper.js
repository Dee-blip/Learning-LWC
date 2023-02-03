({
    removeBtnCSS: function(component) {
    	$A.util.removeClass(component.find('first'),'uiButton--default uiButton');
        $A.util.removeClass(component.find('previous'),'uiButton--default uiButton');
        $A.util.removeClass(component.find('next'),'uiButton--default uiButton');
        $A.util.removeClass(component.find('last'),'uiButton--default uiButton');
    },
    
    pageRecords : function(component, event, helper, flag) {



        var buttonval = "";
        if (flag === true) {
            buttonval = "first";
        } else {
        	buttonval = event.getSource().getLocalId().toLowerCase();    
        }
        console.log('pagination:pageRecords:flag=' + flag);
        console.log("pageRecords:buttonval = "+buttonval);
        if (buttonval) {
            var pagelimit = component.get("v.pagelimit"), offsetvalue = component.get("v.offset"), 
                totalrows = component.get("v.resultsetsize");
            console.log("pageRecords:pagelimit = "+pagelimit);
            console.log("pageRecords:resultsetsize = "+totalrows);
            if (buttonval === "first") {
                offsetvalue = 0;
                component.set("v.isLast", false);
                console.log("pageRecords:first page block = "+offsetvalue);
            } else if (buttonval === "previous") {
                offsetvalue = (offsetvalue - pagelimit) * 1;
                component.set("v.isLast", false);
                console.log("pageRecords:previous page block = "+offsetvalue);
            } 
            else if (buttonval === "last" || buttonval === "next") {
                if (totalrows > (offsetvalue + pagelimit) && buttonval === "next") {
                    offsetvalue = (offsetvalue + pagelimit) * 1;
                    component.set("v.isLast", false);
                    console.log("pageRecords:next page block = "+offsetvalue);
                }
                if (buttonval === "last" || totalrows <= (offsetvalue + pagelimit) ) {
                	var currentpage = (totalrows % pagelimit) > 0 ? Math.floor(totalrows / pagelimit) + 1  : Math.floor(totalrows / pagelimit);
                    console.log("pageRecords:last page block = "+currentpage);
                    offsetvalue =  (currentpage - 1) * pagelimit * 1;
                    component.set("v.isLast", true);
                }
            }
            console.log("pageRecords:offsetvalue = "+offsetvalue);
            component.set("v.offset", offsetvalue);
         
        //  var pageEvt = $A.get("e.c:PaginationEvent");
        //  pageEvt.setParams({ "pagevalue":offsetvalue});
        //  pageEvt.fire();
            
            //Firing Component Event.
            var compEvt = component.getEvent("compEventPagination");
            compEvt.setParams({ "pagevalue":offsetvalue});
            console.log('compEve=' + JSON.stringify(compEvt));
            compEvt.fire();

        }    
    }
})