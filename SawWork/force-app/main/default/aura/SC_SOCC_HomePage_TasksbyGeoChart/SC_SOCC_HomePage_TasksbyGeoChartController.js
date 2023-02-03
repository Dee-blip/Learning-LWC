({
    scriptsLoaded : function(component, event, helper) {
        component.set("v.loaded","true");
        var action = component.get("c.getTaskcountBygeo");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.loaded","false");
                let val = response.getReturnValue() ;
                var labelset=['APJ','EMEA','Americas'] ;
                var dataset=[val[0].apj,val[0].emea,val[0].americas] ;
                new Chart(document.getElementById("pie-geo-chart"), {
                    type: 'bar',
                    data: {
                        labels:labelset,
                        datasets: [{
                            label: "Count of Tasks by Geography (Due within 0-6hrs)",
                            "fill":false,
                            backgroundColor: ["rgb(255, 99, 132)","rgb(54, 162, 235)","rgb(255, 205, 86)"],
                            data: dataset
                        }]
                    }
                }
                          
                         );
            }
        });
        $A.enqueueAction(action);
        
    },
     handleSelect : function(component, event, helper) {
        
        var ref = component.get('c.scriptsLoaded');
                $A.enqueueAction(ref);
    }
})