({
    starRatingGeneratorhelper : function(cmp,event,i,selectedClass) {
        var cmp;
        $A.createComponent('lightning:buttonIcon',{
            "iconName": "utility:favorite",
            "variant": "bare",
            "aura:id":i,
            "alternativeText":i,
            "value":i,
            "iconClass":selectedClass||"",
            "size":"large",
            "onclick": cmp.getReference("c.getClickedValueHelper")
        },function(newStar, status, errorMessage){
            //Add the new star to the body array
            if (status === "SUCCESS") {
                var body = cmp.get("v.body");
                body.push(newStar);
                cmp.set("v.body", body);
                
            }
            else if (status === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                // Show offline error
            }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
        });
    },//
    IterateStarHelper : function(cmp,event,value) {
        var baseIterationValue = cmp.get('v.baseIterationValue'); //getting the base iteration value
        cmp.set("v.body", []);//clearing the body before rendering another element
        
        for(var i=baseIterationValue;i>0;i--)
        {   
            if( i > value){ 
                this.starRatingGeneratorhelper(cmp,event,i,"");
            } else { 
                this.starRatingGeneratorhelper(cmp,event,i,"glow");
            }         
        }//for
    }//
    
})