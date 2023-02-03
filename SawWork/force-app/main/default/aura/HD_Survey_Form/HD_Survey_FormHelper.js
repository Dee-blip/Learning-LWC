({
    cmpArrayBuilderHelper : function(type, value, title, order, options,cmpformArray,meta) { //use this to create cmp nested array
        //console.log('data: '+type+' -- '+value+' -- '+title+' -- '+options)
        var cmpArray = [];
        switch(type)
        {
            case "slider":
                //this.createComponentHelper(cmp,event,body,"c:HD_Survey_Form_slider",value,title,options);
                cmpArray.push("c:HD_Survey_Form_slider",{
                    "value": value,
                    "title":title,
                    "min": meta.min ? meta.min : "0",
                    "max": meta.max ? meta.max : "10",
                    "options":options!=='undefined'?options:[]                    
                });
                break;
                
            case "checkbox":
                //this.createComponentHelper(cmp,event,body,"c:HD_Survey_Form_checkboxGroup",value,title,options);
                cmpArray.push("c:HD_Survey_Form_checkboxGroup",{
                    "value": value,
                    "title":title,
                    "options":options
                });
                break;
                
            case "selectlist":
                //this.createComponentHelper(cmp,event,body,"c:HD_Survey_Form_selectList",value,title,options);
                cmpArray.push("c:HD_Survey_Form_selectList",{
                    "value": value,
                    "title":title,
                    "options":options!=='undefined'?options:[]                    
                });
                break;
                
            case "radio":
                //this.createComponentHelper(cmp,event,body,"c:HD_Survey_Form_radioGroup",value,title,options);
                cmpArray.push("c:HD_Survey_Form_radioGroup",{
                    "value": value,
                    "title":title,
                    "order": order,
                    "options":options!=='undefined'?options:[]                    
                });
                break;
                
            case "textarea":
                //this.createComponentHelper(cmp,event,body,"c:HD_Survey_Form_textArea",value,title,options);
                cmpArray.push("c:HD_Survey_Form_textArea",{
                    "value": value,
                    "title":title,
                    "options":options!=='undefined'?options:[]                   
                });
                break;
                
            case "star":
                //this.createComponentHelper(cmp,event,body,"c:HD_Survey_Form_textArea",value,title,options);
                cmpArray.push("c:HD_Survey_Form_star_rating",{
                    "value": value,
                    "title": title,
                    "options":options!=='undefined'?options:[]                   
                });
                break;
                
            case "sentiment":
                //this.createComponentHelper(cmp,event,body,"c:HD_Survey_Form_textArea",value,title,options);
                cmpArray.push("c:HD_Survey_Form_sentiment",{
                    "value": value,
                    "title": title,
                    "options":options!=='undefined'?options:[]                   
                });
                break;
                
            case "like":
                //this.createComponentHelper(cmp,event,body,"c:HD_Survey_Form_textArea",value,title,options);
                cmpArray.push("c:HD_Survey_Form_like",{
                    "value": value,
                    "title": title,
                    "options":options!=='undefined'?options:[]                   
                });
                break;
        }
        
        cmpformArray.push(cmpArray);//adding it to form array
    },//
    createComponentsHelper : function(cmp,event,componentArray){ //generated component from an array
        //debugger
        $A.createComponents(componentArray,
                            function(components,status, errorMessage){
                                
                                if(status === "SUCCESS"){
                                    console.log('pandya');
                                    cmp.set('v.loaded',true);
                                    cmp.set("v.body", components);
                                    
                                }
                                else if(status === "INCOMPLETE"){
                                    console.log("No response from server or client is offline.")
                                }
                                    else if(status === "ERROR"){
                                        console.log("Error: "+errorMessage);
                                    }
                            });
    },//
    FetchFormDataHelper : function(cmp,event){ //this is promise returned datafetched        
        var RecordId = cmp.get("v.recordId");
        var team = cmp.get("v.team");        
        return new Promise((resolve, reject)=>{
            var HD_Survey_Form_Ctrl = cmp.get('c.ClassObject');
            HD_Survey_Form_Ctrl.setParams({
            IncidentId : RecordId,
            Team : team
        });
        HD_Survey_Form_Ctrl.setCallback(this,function(resp){
            var state = resp.getState();
            if(state === "SUCCESS"){
                var ClassObject = resp.getReturnValue();
                resolve(ClassObject);
            }//SUCCESS
            else if(state === 'ERROR')
            {
                var errors = resp.getError();
                reject(errors);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }  
            }//ERROR
        });
        $A.enqueueAction(HD_Survey_Form_Ctrl); 
    });//promise
}//
 })