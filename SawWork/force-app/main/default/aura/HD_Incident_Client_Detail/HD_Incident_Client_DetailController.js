({
    
    imageError: function(component,event,helper){
        //event.target.onerror=null;
        //event.target.style.visibility = "hidden";
        event.target.style.display = "none";
        var elm = component.find('clientimage');
        
        $A.util.addClass(elm, 'hideMe');

    }, 
    imageSucces : function(component,event,helper){
        event.target.onerror=null;
        event.target.style.display = "block";
        var imgdiv = event.target.parentNode;
        imgdiv.className = imgdiv.className + " slds-p-bottom--small";
        console.log(event.target.parentNode.className);        
        console.log('success fired');
        var elm = component.find('clientimage');
        
        $A.util.addClass(elm, 'showMe');
        //event.target.style.visibility = "visible";
    }, 
	activeTab : function(component, event, helper) {
		console.log('test me');
        console.log(this.parent);
	},
    populateClientInfo : function(component, event, helper) 
    {   
        console.log("event handling!!!!!");
        console.log(document.title);
        
        
        var action = component.get("c.getClientInfo");
        var action2 = component.get("c.getTicketDetails");        
        var incId = component.get("v.recordId");
        
        action2.setParams({
            recordId : incId    
        });
        
        action.setParams({
        	recordId : incId
        });
        
        action2.setCallback(this,function(data){
        	var data = data.getReturnValue();
            console.log('Data received');
            console.log(data);
            var details = {};
            
            
            if( data.username != null){
                details.url="https://contacts.akamai.com/photos/"+data.username.substring(0,data.username.indexOf('@'))+".jpg";
            }
            
            //console.log(imageExists(details.url));
            //console.log(data.username.substring(0,data.username.indexOf('@')));//.substring(0,indexOf("@")));
            details.summary = data.summary;
            details.owner = data.owner;
            details.resolution = data.resolution;
            details.type = data.type;
            details.requestTitle = data.requestTitle;
            details.shortDescription = data.shortDescription;
            
            var prefix;
            if(data.type == 'Incident')
            {
                prefix = 'IN';
            }
            else
            {
                //var cmpTarget = component.find('srComponent');
				//$A.util.addClass(cmpTarget, 'showMe');
				//var cmpTarget = component.find('ticketSummary');
				//$A.util.addClass(cmpTarget, 'hideMe');
                prefix = 'SR';
            }
            document.title = prefix+data.name;
            
            component.set("v.ticketDetails",details);
            component.set("v.placeHolder", false);
        });
        
       
        
        action.setCallback(this,function(data){
            
            console.log(data);
            console.log(data.getReturnValue());
            var clientObj  = data.getReturnValue(); // js object -- with key -value pair
            var clientInfolist = [];
             for(var label in clientObj){
                 var lbl;
                 
                     
                 
                 console.log(label);
                 console.log(clientObj[label]);
                 console.log(label.indexOf('Client'));
                 if(label.indexOf('Client')==0)
                 {
                     lbl = label.substring(label.indexOf('Client')+6);
                 }
                 console.log(lbl);
                 var labelValue = [lbl,clientObj[label]];
                 clientInfolist.push(labelValue)
                 
                 }
             console.log("print mastrer");
             console.log(clientInfolist);
            //console.log(x["Client Name"]);
            component.set("v.clientDetails", clientInfolist);
            
        });
        /*var test = {
                "description" : "My desc"
            }
        component.set(ticketDetails,test);*/
        /*var incId = component.get("v.recordId");
        var action2 = component.get("c.getTicketDetails")
        action2.setParams({
        	recordId : incId
        });
        action2.setCallback(this,function(data){
        	console.log('Pranav');
            
            
        });
		$A.enqueueAction(action2);*/
		$A.enqueueAction(action);
        $A.enqueueAction(action2);
        
        
	},
    
    showSummary : function(component, event, helper) {
        console.log('show summary');
        
        //console.log(document.getElementById("summaryId").style.display);
       /* if(document.getElementById("summaryId").style.display=="none")
        document.getElementById("summaryId").style.display = "block";*/
       //document.getElementById("summaryId").style.visibility = "visible";
		 var cmp=component.find("summaryId");
        //console.log(document.getElementById("summaryId").style.display);
		$A.util.addClass(cmp,"custom-show-modal");
        $A.util.removeClass(cmp,"custom-hide-modal");
        
    },
    
    hideSummary : function(component,event, helper){
       console.log('hide summary');


       //console.log(document.getElementById("summaryId").style.display);
        
       //document.getElementById("summaryId").style.display = "none" ;
              // document.getElementById("summaryId").style.visibility = "hidden";
              var cmp=component.find("summaryId");
       //console.log(document.getElementById("summaryId").style.display);
        $A.util.addClass(cmp,"custom-hide-modal");
        $A.util.removeClass(cmp,"custom-show-modal");

   },

    showResolution : function(component, event, helper) {
        //document.getElementById("resolutionId").style.display = "block";
		var cmp=component.find("resolutionId");
		$A.util.addClass(cmp,"custom-show-modal");
        $A.util.removeClass(cmp,"custom-hide-modal");
    },
    
    hideResolution : function(component,event, helper){
       //document.getElementById("resolutionId").style.display = "none" ;
       var cmp=component.find("resolutionId");
       //console.log(document.getElementById("summaryId").style.display);
        $A.util.addClass(cmp,"custom-hide-modal");
        $A.util.removeClass(cmp,"custom-show-modal");

   },
    showRequestTitle : function(component, event, helper) {
        //document.getElementById("resolutionId").style.display = "block";
		var cmp=component.find("requestTitleId");
		$A.util.addClass(cmp,"custom-show-modal");
        $A.util.removeClass(cmp,"custom-hide-modal");
    },
    
    hideRequestTitle : function(component,event, helper){
       //document.getElementById("resolutionId").style.display = "none" ;
       var cmp=component.find("requestTitleId");
       //console.log(document.getElementById("summaryId").style.display);
        $A.util.addClass(cmp,"custom-hide-modal");
        $A.util.removeClass(cmp,"custom-show-modal");

   },
    
    
    httpGet: function(theUrl, callback)
    {
        var xmlHttp = new XMLHttpRequest();
        xmlHttp.onreadystatechange = function() { 
            if (xmlHttp.readyState == 4 && xmlHttp.status == 200)
                callback(xmlHttp.responseText);
        }
        xmlHttp.open("GET", theUrl, true); // true for asynchronous 
        xmlHttp.send(null);
    },
    
    handleEvent: function(component,event)
    {
        console.log("event handling!!!!!");
    }    
    

})