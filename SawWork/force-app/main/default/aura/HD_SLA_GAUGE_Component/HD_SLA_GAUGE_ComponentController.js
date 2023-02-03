({
    generateGauge : function(component, event, helper) {
        
        //helper.createGauge(component, event, helper);
        //helper.getSLAinfo(component, event, helper);
        var showSLAinfo = component.get('v.ShowSLAinfo');
        var getSLAinfoPromise = helper.getSLAinfoPromise(component);
        getSLAinfoPromise.then
        (
            $A.getCallback(function(result){
                //console.log("Promise Delivered ! :)");
                var responseDiv = document.getElementById("response_title");
                var resolutionDiv = document.getElementById("resolution_title");
                responseDiv.innerHTML = "<Strong>Response</Strong>";
                resolutionDiv.innerHTML = "<Strong>Resolution</Strong>";
                helper.createGauge(component);
                showSLAinfo = component.get('v.ShowSLAinfo');
                
                if(showSLAinfo == true)
                {
                    console.log('>>>Polling....'+showSLAinfo);
                    var SLAPoller = window.setInterval(
                        $A.getCallback(function() {
                            var responseSLAPercentage = component.get("v.Response_Percentage");
                            
                            var responseDiv = document.getElementById("response");
                            var resolutionDiv = document.getElementById("resolution");
                            console.log('Calling the function...');
                            var getSLAinfoPromise = helper.getSLAinfoPromise(component);
                            getSLAinfoPromise.then
                            (
                                $A.getCallback(function(result){
                                    responseDiv.innerHTML = "<Strong>Response</Strong>";
                                    resolutionDiv.innerHTML = "<Strong>Resolution</Strong>";
                                    helper.createGauge(component);
                                    
                                    // 
                                }),
                                $A.getCallback(function(error){
                                    // Something went wrong
                                    console.log('An error occurred getting the details : ' + error.message);
                                })
                            );
                            console.log("Controller Resonse percentage >>>>"+responseSLAPercentage);
                            if( responseSLAPercentage > 100)
                            {
                                clearInterval(SLAPoller);
                            }
                            
                        }), 600000
                    );//interval
                }//if(showSLAinfo == true)
                // 
            }),
            $A.getCallback(function(error){
                // Something went wrong
                console.log('An error occurred getting the details : ' + error.message);
            })
        );

    },
    showHide : function(component, event, helper)
    {
        helper.showOrhideHelper(component, event, helper);
    },
    closepopover : function(component, event, helper)
    {
        helper.closePopoverHelper(component, event, helper);
    },
    
    
})