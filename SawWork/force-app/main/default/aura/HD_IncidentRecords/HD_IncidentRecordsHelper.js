({
	fireToast : function(cmp) {
		var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({

             "message": "No records found."
        });
       toastEvent.fire();
	},
    showHelp : function(cmp) {
        if(cmp.get("v.shown")==false)
        {
            var help = document.getElementById("help");
            if(help)
            {
               help.style.display = "block"; 
            
            
                setTimeout(function(){ 
                    help.style.display = "none";
                }, 3000);
                
                cmp.set("v.shown",true);
            }
        }
		
	},
   
    adjustTableWidth : function(cmp){
        for(var i=0; i<11;i++){
            var pid = 'thid'+i;
            var cid = 'dvid'+i;
            var parent =document.getElementById(pid);
            
        	var child = document.getElementById(cid);
            if(parent!=null){
                var eleWidth = parent.clientWidth;
                //eleWidth = 0.9*eleWidth;
				child.style.width = eleWidth+'px';      
            }
        }
        
        
        var parent = document.getElementById('incNumColHead');
        var child = document.getElementById('incNumColHeadValue');
        var eleWidth = parent.clientWidth;
        //eleWidth = 0.9*eleWidth;
        child.style.width = eleWidth+'px';      
    	
    },
    
    adjustTableHeight : function(cmp){
        //var ele = cmp.find("qwerty");
        //childNodes
      	var ele = document.getElementById('qwerty');
        //alert(ele);
        var browserHeight = document.documentElement.clientHeight;
        browserHeight -= 170;
        var finalHeight = browserHeight+ 'px';
        //alert(finalHeight);
        ele.style.height = finalHeight;
    },
    
    
    sortHelper: function(component, event) {
      var currentDir = component.get("v.arrowDirection");
 
      if (currentDir == 'arrowdown') {
         // set the arrowDirection attribute for conditionally rendred arrow sign  
         component.set("v.arrowDirection", 'arrowup');
         // set the sortDirection flag to true for sort in Ascending order.  
         component.set("v.sortDirection", "ASC");
      } else {
         component.set("v.arrowDirection", 'arrowdown');
         component.set("v.sortDirection", "DESC");
      }
   },
    
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },
    
    getIncidentRecords: function(cmp,evt) {
        cmp.set("v.previewFlag","false");
        this.toggleSpinner(cmp,evt);
        
        var recVal = evt.getParam("numRecords");
        var viewVal = evt.getParam("fltrId");
        var ticketNumber = evt.getParam("searchVal");
        var pageNum = evt.getParam("pageNum");
        var sortBy = evt.getParam("sortBy");
        var sortDirection = evt.getParam("sortDirection");
        var pageN = parseInt(pageNum);
        var action = cmp.get("c.getIncidentList");
            action.setParams({
                noOfRecs : recVal,
        		filterId : viewVal,
                ticketNumber : ticketNumber,
                pageNo : pageN,
                orderBy : sortBy,
                sortDirection : sortDirection
                
      		});
            
            action.setCallback(this,function(data){
				                
                this.toggleSpinner(cmp,evt);
                var state = data.getState();
                if(state == 'ERROR'){
                     var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type":"error",
                        "message": "Error occurred."
                    });
                    toastEvent.fire();
                    return;
                }
                var response = data.getReturnValue();
                if(!response.records){
                     var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type":"error",
                        "message": "Error occurred."
                    });
                    toastEvent.fire();
                    return;
                }
                cmp.set("v.incidents",response.records);
                
                var noOfPagesEvent = $A.get("e.c:HD_noOfPagesEvent");
                noOfPagesEvent.setParams({"noOfPages":response.noOfPages,"noOfRecords":response.noOfRecords}).fire();
                
                
                if(response.records.length == 0)
                {
                    
                    this.fireToast(cmp);
                }
                /*var res = [];
                var fieldApis = cmp.get("v.colApis");
                response.records.forEach(function(record) {
                    var result = {};
                    
                    fieldApis.forEach(function(field) {
                        if(record[field])
                        {
                            result[field]=record[field];
                        }
                    });
                    
                    res.push(result);
                });
              	
                
                console.log(res);*/
                

    		});
            $A.enqueueAction(action);
        cmp.set("v.selected",[]);
        cmp.set("v.selectedData",[]);
        cmp.set("v.shown",false);
         
    }
    
})