({
	initAction : function(component, event, helper) {
        var listUsers = component.get("c.listUsers");
        listUsers.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            {
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
            else if(state == "ERROR")
            {
                var error = resp.getError();
                if(error)
                {
                 	console.log(error);
                }
            }
        });
        $A.enqueueAction(listUsers);
    },
    
    /*initActionOnProfile : function(component, event, helper) {
        console.log("inClick2");
        var showProfileName = event.getParam("ProfileName");
        component.set("v.test", showProfileName);
    }*/
    
    //Testing of child component
    executeMyMethod : function (component, event, helper) {
        var params = event.getParam('arguments');
        //alert('Param 1: '+ params.param1);
        
        var listUsers2 = component.get("c.listUsers2");
        listUsers2.setParams({"active":params.param1});
        listUsers2.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
                
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(listUsers2);   
    },
    
    executesixmonths : function (component, event, helper) {
        var params = event.getParam('arguments');
        
        var listUsers3 = component.get("c.listUsers3");
        listUsers3.setParams({"duration":params.param1});
        listUsers3.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
                
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(listUsers3); 
    },
    
    executeusernotowner : function (component, event, helper){
        var params = event.getParam('arguments');
        
        var listUsers4 = component.get("c.listUsers4");
        listUsers4.setParams({"duration":params.param1});
        listUsers4.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
                
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(listUsers4); 
    },
    
    callRecord : function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.target.id,//"005A0000001YVypIAG",
            "slideDevName": "related"
        });
        navEvt.fire();
    },
    
    //methods for frequency of users
    executemodifications : function (component, event, helper){
        
        var params = event.getParam('arguments');
        
        var modifications = component.get("c.modifications");
        
        modifications.setParams({"frome":params.param1,"to":params.param2,"dur":params.param3});
        
        modifications.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(modifications); 
    },
    
    /*executerare : function (component, event, helper){
        var bluemoon = component.get("c.rare");
        bluemoon.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(bluemoon); 
    },
    
    executeoften : function (component, event, helper){
        var bluemoon = component.get("c.often");
        bluemoon.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(bluemoon); 
    },
    
    executeaverage : function (component, event, helper){
        var bluemoon = component.get("c.average");
        bluemoon.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(bluemoon); 
    },
    
    executeregular : function (component, event, helper){
        console.log("in table controller");
        var regular = component.get("c.regular");
        regular.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                console.log("In success");
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                console.log("in running");
            }
                else if(state == "ERROR")
                {
                    console.log("In error");
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
            
        });
        
        $A.enqueueAction(regular); 
    },
    
    executenerdy : function (component, event, helper){
        var bluemoon = component.get("c.nerdy");
        bluemoon.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(bluemoon); 
    },*/
    
    //for no.of tickets
    executebluemoont : function (component, event, helper){
        var params = event.getParam('arguments');
        //alert(params.param2);
        //console.log(params.param2)
        var bluemoont = component.get("c.bluemoont");
        bluemoont.setParams({"UID":params.param2});
        bluemoont.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    console.log("hiiiii")
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(bluemoont); 
    },
    
    /*executeraret : function (component, event, helper){
        var params = event.getParam('arguments');
        console.log(params.param2)
        var raret = component.get("c.raret");
        raret.setParams({"UID":params.param2});
        raret.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    console.log("hiiiii")
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(raret); 
    },
    
    executeoftent : function (component, event, helper){
        var params = event.getParam('arguments');
        console.log(params.param2)
        var oftent = component.get("c.oftent");
        oftent.setParams({"UID":params.param2});
        oftent.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    console.log("hiiiii")
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(oftent); 
    },
    
    executeregulart : function (component, event, helper){
        var params = event.getParam('arguments');
        console.log(params.param2)
        var regulart = component.get("c.regulart");
        regulart.setParams({"UID":params.param2});
        regulart.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    console.log("hiiiii")
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(regulart); 
    },
    
    executenerdyt : function (component, event, helper){
        var params = event.getParam('arguments');
        console.log(params.param2)
        var nerdyt = component.get("c.nerdyt");
        nerdyt.setParams({"UID":params.param2});
        nerdyt.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            { 
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    console.log("hiiiii")
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(nerdyt); 
    },*/
})