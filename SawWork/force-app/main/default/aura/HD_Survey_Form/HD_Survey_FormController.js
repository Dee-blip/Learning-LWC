({
    initAction : function(cmp, event, helper) {
        var cmpformArray = [];      
        helper.FetchFormDataHelper(cmp, event).then($A.getCallback(function(Classobject){ //get callback is the real deal here
            console.log(Classobject);
            var sform = Classobject.sform[0];
            var inc = Classobject.inc[0];
            cmp.set('v.form_meta',JSON.parse(sform.Form_meta__c));
            cmp.set('v.survey_title',sform.Survey_Title__c);
            cmp.set('v.survey_user',Classobject.currentUserName);
            cmp.set('v.survey_date', new Date().toDateString());
            cmp.set('v.survey_type',sform.Survey_Type__c);
            cmp.set('v.survey_user_Id',Classobject.currentUserID); 
            cmp.set('v.survey_form_Id',sform.Id);
            cmp.set('v.Survey_Intro',sform.Survey_Intro__c)
            cmp.set('v.Inc_Id',inc?inc.Id:'');
            
            //Survey already taken attribute set
            cmp.set('v.survey_taken_flag',Classobject.surveyAlreadyTaken);
            //Msg: Response Already Submitted for this Survey. ThankYou.
            if(cmp.get('v.survey_taken_flag'))
            {
                cmp.set('v.survey_taken_message','Response already submitted for this survey. Thank You!');
            }
            
            
            //Start of Form Meta Builder
            var idx = 1;
            var form_meta = cmp.get('v.form_meta');
            for(var key in form_meta)
            {  
                var RefMeta  = cmp.getReference("v.form_meta["+key+"].value");
                helper.cmpArrayBuilderHelper(form_meta[key].type,RefMeta, idx+". "+form_meta[key].title, idx, form_meta[key].options,cmpformArray, form_meta[key]);
                idx = idx+1;   
            }
            //console.log(JSON.stringify(cmpformArray));
            cmp.set('v.cmp_array',cmpformArray);
            helper.createComponentsHelper(cmp,event,cmp.get('v.cmp_array'))
            //END Start of Form Meta Builder
        })).catch((e)=>{
            console.log(e);
        });
        //PRTORES-1650 - dynamic footer year
        cmp.set('v.currentDate', new Date());
        },
            submitClick : function (cmp, event, helper) { //action for saving the response
                var form_meta = cmp.get('v.form_meta');
                var form_meta_Array = [];
                for(var key in form_meta)
                {
                    var current_meta = form_meta[key];
                    if(typeof current_meta.value === 'object')
                    {
                        console.log('object value detectted --> ',current_meta.value.join());
                        form_meta[key].value = current_meta.value.join();
                    }
                    
                    form_meta_Array.push(JSON.stringify(form_meta[key]));
                }
                
                var saveSurveyResponse = cmp.get('c.saveSurveyResponse');
                saveSurveyResponse.setParams({
                    'surveyFormResponse':form_meta_Array,
                    'survey_form_id':cmp.get('v.survey_form_Id'),
                    'incident_Id':cmp.get('v.Inc_Id') ,
                    'survey_user_Id':cmp.get('v.survey_user_Id')
                });
                saveSurveyResponse.setCallback(this,function(resp){
                    var state = resp.getState();
                    if(state === "SUCCESS"){
                        var saveResp = resp.getReturnValue();
                        console.log('survet save flag --> ', saveResp)
                        if(saveResp)
                        {
                            cmp.set('v.survey_taken_flag',true);//setting the flag true once the response is submitted.
                        }//    
                        
                    }//SUCCESS
                    else if(state === "INCOMPLETE"){
                        console.log('incomplete');
                    }
                        else if(state === "ERROR"){
                            var errors = resp.getError();
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
                
                console.log(JSON.stringify(form_meta));
                // alert("You clicked: " + event.getSource().get("v.label"));
                $A.enqueueAction(saveSurveyResponse); 
            }
            
        })