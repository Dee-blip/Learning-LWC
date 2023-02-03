({
	fireToast : function(cmp) {
		var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({

             "message": "No records found."
        });
       toastEvent.fire();
	},
    
    adjustTableWidth : function(cmp){
       
        for(var i=0; i<11;i++){
            var pid = 'thid'+i;
            var cid = 'dvid'+i;
            var parent =document.getElementById(pid);
            
        	var child = document.getElementById(cid);
            if(parent!=null){
                var eleWidth = parent.clientWidth;
                if(child){
				child.style.width = eleWidth+'px';}      
            }
        }
        
        
        var parent = document.getElementById('incNumColHead');
        var child = document.getElementById('incNumColHeadValue');
        if(parent!=null){var eleWidth = parent.clientWidth;}
        if(child){child.style.width = eleWidth+'px';}     
    	
    },
    
    adjustTableHeight : function(cmp){
        //var ele = cmp.find("qwerty");
        //childNodes
      	var ele = document.getElementById('qwerty');
        //alert(ele);
        var browserHeight = document.documentElement.clientHeight;
        browserHeight -= 170;
        var finalHeight = browserHeight+ 'px';
        if(ele){ele.style.height = finalHeight;}
    },
    
    
    sortHelper: function(component, event) {
      var currentDir = component.get("v.arrowDirection");
 
      if (currentDir == 'arrowdown') {
         
         component.set("v.arrowDirection", 'arrowup');
         
         component.set("v.sortDirection", "ASC");
      } else {
         component.set("v.arrowDirection", 'arrowdown');
         component.set("v.sortDirection", "DESC");
      }
   }
    
})