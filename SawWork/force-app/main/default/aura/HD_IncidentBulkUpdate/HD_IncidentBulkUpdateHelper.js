({
	calculateInactiveTime: function(component,event)
    {
        var startInactiveTime;
        var endInactiveTime;
        var flag = false;
        var idleTime;
        window.onblur = function() { 
            
            console.log('window blur'); 
            var startTime = component.get("v.startTime");
            if(startTime)
            {
                flag = true;
                startInactiveTime = new Date();
            }
        }
        window.onfocus = function() {
            
			if(flag)
            {
               flag = false; 
               var st = new Date(component.get("v.startTime"));
                                 
               if(startInactiveTime-new Date(component.get("v.startTime"))>0)
               {
                   endInactiveTime = new Date();
               	   idleTime =  parseInt((endInactiveTime- startInactiveTime)/1000);
               
               		component.set("v.idleTime",component.get("v.idleTime")+idleTime);
               }
               console.log('window focus'+component.get("v.idleTime"));
            }
             
            
        }
    }
})