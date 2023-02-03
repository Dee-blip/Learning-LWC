({    
    scriptsLoaded : function(component, event, helper) {
        component.set("v.loaded","true");
        var action = component.get("c.getTaskcountByDueDate");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.loaded","false");
                let val = response.getReturnValue() ;
                var labelset=['Overdue by : 0-6Hrs','Due within : 0-6Hrs','Due within : 6-12Hrs','Due within > 12Hrs'] ;
                var dataset=[val[0].TaskCountbelow0to6,val[0].TaskCount0to6,val[0].TaskCount6to12,val[0].TaskCountabove12] ;
                new Chart(document.getElementById("pie-chart"), {
                    type: 'bar',
                    data: {
                        labels:labelset,
                        datasets: [{
                            label: "Count of Tasks by due date",
                            "fill":false,
                            backgroundColor: ["rgba(153, 102, 255, 0.2)","rgba(255, 99, 132, 0.2)","rgba(255, 159, 64, 0.2)","rgba(75, 192, 192, 0.2)","rgba(54, 162, 235, 0.2)"],
                            borderColor	:["rgb(153, 102, 255)","rgb(255, 99, 132)","rgb(255, 159, 64)","rgb(75, 192, 192)","rgb(54, 162, 235)"],
                            "borderWidth":1,
                            data: dataset
                        },{
                            
                            label: "Tasks trend by Due Date",
                            type: "line",
                            "fill":true,
                            "borderColor":"rgb(248,229,173)",
                            backgroundColor	:"rgba(248,229,173,.2)",
                            "lineTension":0.5,
                            
                            data: dataset
                        }
                                  ]
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
    },
    openfullscreen:function(component, event, helper) 
            { 
                window.open('/apex/SC_SOCC_HomePage_LCOut_VF', '_self'); 
            },
    
        })