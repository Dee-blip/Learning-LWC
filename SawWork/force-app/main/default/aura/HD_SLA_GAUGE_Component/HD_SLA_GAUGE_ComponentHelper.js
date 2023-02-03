({
    showOrhideHelper : function(component, event, helper)
    {
        var popoverId = component.find("slapopover"); 
        $A.util.removeClass(popoverId,"slds-hide");
        console.log("mouse overed");
    },
    closePopoverHelper : function(component, event, helper)
    {
        var popoverId = component.find("slapopover"); 
        $A.util.addClass(popoverId,"slds-hide");
        console.log("Class Added");
    },
    createGauge : function(component){
        //var gaugeRenderFlag = component.get("v.gaugeRenderFlag");
        //grabbing the changed values in to the gauge hub
        var resp_percentage = component.get("v.Response_Percentage");
        var reso_percentage = component.get("v.Resolution_percentage");
        //console.log("line 19 Resp>>>> "+resp_percentage+" Reso>>>>"+reso_percentage);
        //adding consditional lines for getting ELements
        var resp_Element  = document.getElementById('response');
        if(resp_Element){resp_Element.innerHTML = "";}//added check for null
        var reso_Element = document.getElementById('resolution');
        if(reso_Element){reso_Element.innerHTML = "";}//added check for null
        //creating the gauge
        var ResponseGauge = new JustGage({
            id: "response",
            value: resp_percentage,
            min: 0,
            max: 100,
        });
        //console.log("REsp Gauge >>> "+ResponseGauge);
        var ResolutionGauge = new JustGage({
            id: "resolution",
            value: reso_percentage,
            min: 0,
            max: 100
        });
        //setting the falg to true now to prevent it rendering again
        //component.get("v.gaugeRenderFlag",true);      
        
    },
    getSLAinfoPromise : function(component,callback) {
        return new Promise(function(resolve,reject){
            var RecordId = component.get("v.recordId");
            var targetObjectIdvalue = "a5U3D000000DGLbUAO";//a5UR0000000AKNF //SLA :a5UR0000000AKOD
            if(RecordId != null )
            {
                targetObjectIdvalue = RecordId;
            }
            //console.log('Promise Current Record ID: >>>>>'+RecordId );    
            var IncidentServicetarget = component.get('c.ClassObject');//component.get('c.getSLADetails');
            IncidentServicetarget.setParams({
                incidentId : targetObjectIdvalue
            });
            IncidentServicetarget.setCallback(this,function(resp){
                var state = resp.getState();
                if( state === "SUCCESS"){
                    var classObjresp = resp.getReturnValue();
                    //console.log('>>>>** '+JSON.stringify(classObjresp));
                    //Getting custom setting for RF_Default_Custom_Setting
                    var RF_Default_Custom_Setting = classObjresp.RF_Default_Custom_Setting;
                    var Response_Threshhold = RF_Default_Custom_Setting.Default_Account__c; //Response
                    var Resolution_threshold = RF_Default_Custom_Setting.Default_Impact__c; //Resolution
                    component.set("v.SLA_GAUGE_RESPONSE_THRESHOLD",Response_Threshhold);
                    component.set("v.SLA_GAUGE_RESOLUTION_THRESHOLD",Resolution_threshold);
                    //console.log('>>>>** '+Resolution_threshold);
                    //Business Logic
                    var IncidentServicetargetResp = classObjresp.sla_details;
                    var cancelledSLAs = [];//used for fetching older SLA applied
                    //console.log(targetObjectIdvalue+'<--- SLA ---> '+IncidentServicetargetResp);
                    if(IncidentServicetargetResp == "")
                    {
                        
                        console.log("No SLA Applied");
                    }
                    else
                    { 
                        var ShowSLAinfo = component.set("v.ShowSLAinfo",true);
                        for(let ISTSLA in IncidentServicetargetResp)
                        {
                            //fetching only valid SLA's info's
                            if(!IncidentServicetargetResp[ISTSLA].BMCServiceDesk__IsCanceled__c)
                            {
                                
                                //getting active response SLA
                                if(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__TargetTypeValue__c == "Response Time" )
                                {
                                    component.set("v.Active_Response_SLA",IncidentServicetargetResp[ISTSLA]);
                                    
                                    //start of finding weather the SLA Missed OR Met for Response based on active one
                                    console.log(' Line 88: '+IncidentServicetargetResp[ISTSLA].BMCServiceDesk__Status__c+'===>'+IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c);
                                    if(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__Status__c == 'Missed')
                                    {
                                        switch(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c)
                                        {
                                            case 'Paused':
                                                component.set("v.Active_Response_SLA_Result",'Missed');
                                                break;
                                            case 'Stopped':
                                                component.set("v.Active_Response_SLA_Result",'Missed');
                                                break;
                                            default:
                                                component.set("v.Active_Response_SLA_Result",'Missed');
                                                
                                        }//switch
                                        console.log('Missed');
                                    }else{
                                        switch(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c)
                                        {
                                            case 'Stopped':
                                                component.set("v.Active_Response_SLA_Result",'Met');
                                                break;
                                            default:      
                                                component.set("v.Active_Response_SLA_Result",'OK');
                                        }//switch
                                       
                                    }//ELSE for rest of the status show OK
                                    //END of SLA result
                                }
                                //getting active Resolution SLA
                                if(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__TargetTypeValue__c == "Resolution Time")
                                {
                                    component.set("v.Active_Resolution_SLA",IncidentServicetargetResp[ISTSLA]);
                                    //start of finding weather the SLA Missed OR Met for Resolution based on active one
                                    console.log(' Line 123: '+IncidentServicetargetResp[ISTSLA].BMCServiceDesk__Status__c+'===>'+IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c);
                                    if(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__Status__c == 'Missed')
                                    {
                                        switch(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c)
                                        {
                                            case 'Paused':
                                                component.set("v.Active_Resolution_SLA_Result",'Missed');
                                                break;
                                            case 'Stopped':
                                                component.set("v.Active_Resolution_SLA_Result",'Missed');
                                                break;
                                            default:
                                                component.set("v.Active_Resolution_SLA_Result",'Missed');
                                                
                                        }//switch
                                        console.log('Missed');
                                    }else{
                                        switch(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c)
                                        {
                                            case 'Stopped':
                                                component.set("v.Active_Resolution_SLA_Result",'Met');
                                                break;
                                            default:      
                                                component.set("v.Active_Resolution_SLA_Result",'OK');
                                        }//switch
                                       
                                    }//ELSE for rest of the status show OK
                                    //END of SLA result
                                }
                                
                                
                                //date entity  
                                var startDate = moment(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__StartDate__c);
                                var targetEndDate = moment(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__TargetEndDate__c);
                                var todayDate = moment();
                                var LastUpdatedDate = moment(IncidentServicetargetResp[ISTSLA].LastModifiedDate);
                                var percentage = 0;
                                //Time remaining calculation
                                var Time_remaining = moment.duration(targetEndDate.diff(todayDate));
                                var Time_remaining_days = 0;
                                var Time_remaining_hours = 0;
                                var Time_remaining_minutes = 0;
                                
                                if(Time_remaining.days() > 0){Time_remaining_days = Time_remaining.days();}
                                if(Time_remaining.hours() > 0){Time_remaining_hours = Time_remaining.hours();}
                                if(Time_remaining.minutes() > 0){Time_remaining_minutes =  Time_remaining.minutes();}
                                
                                //console.log('Duration calculation : --> days:'+days+' hours:'+hours+' minutes:'+minutes); 
                                
                                //calculating percentage based on duration strategy
                                if( IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c != ('Paused' || 'Stopped') ){ 
                                    var todaydate_startDateOnly = todayDate.diff(startDate);
                                    var targetdate_startDateOnly = targetEndDate.diff(startDate);
                                    percentage = (100 * todaydate_startDateOnly / targetdate_startDateOnly ).toFixed(2);
                                }else if(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c === 'Not Started'){
                                    console.log('Clock not started !');
                                    percentage = 0;
                                }else{   
                                    try{
                                        console.log('SLA Clock Paused ! taking LastUpdate Strategy !'+ IncidentServicetargetResp[ISTSLA].LastModifiedDate);
                                        var lastupdate_startDateOnly = LastUpdatedDate.diff(startDate);
                                        var targetdate_startDateOnly = targetEndDate.diff(startDate);
                                        percentage = (100 * lastupdate_startDateOnly / targetdate_startDateOnly ).toFixed(2);
                                    }catch(err){
                                        console.log('--->'+err);
                                    }
                                }//else
                                
                                console.log('percentage >>>>>> '+ percentage );        
                                //fix for NaN
                                if( isNaN(percentage) )//scenario where last updated date is not populated it throws NaN
                                {   
                                    console.log('Value is coming NaN, hence making Zero');
                                    percentage = 0;
                                }
                                //condition for not started
                                if(IncidentServicetargetResp[ISTSLA].BMCServiceDesk__ClockState__c === 'Not Started')
                                {
                                    console.log('Clock not started !'+IncidentServicetargetResp[ISTSLA].BMCServiceDesk__TargetTypeValue__c+' SLA');
                                    percentage = 0;
                                }
                                
                                //Assigning Percentage to SLA Reponse and Resolution                                
                                if( IncidentServicetargetResp[ISTSLA].BMCServiceDesk__TargetTypeValue__c == "Response Time" )
                                {
                                    var Timeremaining_RespTime = Time_remaining_days+" Days "+Time_remaining_hours+" Hours "+Time_remaining_minutes+" Minutes";   
                                    if( (percentage > 100) || (IncidentServicetargetResp[ISTSLA].BMCServiceDesk__Status__c == "Missed" ) )
                                    {
                                        percentage = 100;
                                        Timeremaining_RespTime = "0 Days 0 Hours 0 Minutes";
                                    }
                                    else if( (percentage < 100) || (IncidentServicetargetResp[ISTSLA].BMCServiceDesk__Status__c != "Missed" ) )
                                    {  
                                        Timeremaining_RespTime = Time_remaining_days+" Days "+Time_remaining_hours+" Hours "+Time_remaining_minutes+" Minutes";
                                    }
                                    component.set("v.Response_Percentage",percentage);
                                    component.set("v.Active_Response_SLA_TimeRemaining",Timeremaining_RespTime)
                                    //adding Reponse Gauge hours left logic here
                                    var SLA_Front_gauge_Response_display = "In Progress..";
                                    if(Time_remaining_days > 0)
                                    {
                                        SLA_Front_gauge_Response_display = Time_remaining_days+" days left";
                                    }
                                    else
                                    {
                                        if(Time_remaining_hours > 0)
                                        {
                                            SLA_Front_gauge_Response_display = Time_remaining_hours+" hours left"
                                        }
                                        else
                                        {
                                            if(Time_remaining_minutes > 0){
                                                SLA_Front_gauge_Response_display = Time_remaining_minutes+" minutes left"
                                            }
                                            else
                                            {
                                                SLA_Front_gauge_Response_display = "0 minutes left";
                                            }//Minutes Else END
                                            
                                        }//hours else END
                                        
                                    }//Days else END
                                    component.set("v.Active_Response_SLA_TimeRemaining_Gauge",SLA_Front_gauge_Response_display);
                                    //END adding Reponse Gauge hours left logic here
                                }
                                if( IncidentServicetargetResp[ISTSLA].BMCServiceDesk__TargetTypeValue__c == "Resolution Time")
                                {
                                    var Timeremaining_ReTime = Time_remaining_days+" Days "+Time_remaining_hours+" Hours "+Time_remaining_minutes+" Minutes";   
                                    if( (percentage > 100) || (IncidentServicetargetResp[ISTSLA].BMCServiceDesk__Status__c == "Missed" ) )
                                    {
                                        percentage = 100;
                                        Timeremaining_ReTime = "0 Days 0 Hours 0 Minutes";
                                    }
                                    //console.log('line201>>>'+percentage);
                                    component.set("v.Resolution_percentage",percentage);
                                    component.set("v.Active_Resolution_SLA_TimeRemaining",Timeremaining_ReTime)
                                    
                                    //adding Resolution Gauge Days  left logic here
                                    var SLA_Front_gauge_Resolution_display = "In Progress..";
                                    if(Time_remaining_days > 0)
                                    {
                                        SLA_Front_gauge_Resolution_display = Time_remaining_days+" days left";
                                    }
                                    else
                                    {
                                        if(Time_remaining_hours > 0)
                                        {
                                            SLA_Front_gauge_Resolution_display = Time_remaining_hours+" hours left"
                                        }
                                        else
                                        {
                                            if(Time_remaining_minutes > 0){
                                                SLA_Front_gauge_Resolution_display = Time_remaining_minutes+" minutes left"
                                            }
                                            else
                                            {
                                                SLA_Front_gauge_Resolution_display = "0 days left";
                                            }//Minutes Else END
                                            
                                        }//hours else END
                                        
                                    }//Days else END
                                    component.set("v.Active_Resolution_SLA_TimeRemaining_Gauge",SLA_Front_gauge_Resolution_display);
                                    //END adding Resolution Gauge hours left logic here
                                }
                                
                            }//if(!IncidentServicetargetResp[ISTSLA].BMCServiceDesk__IsCanceled__c)
                            else //fetching older applied SLA's
                            {
                                cancelledSLAs.push(IncidentServicetargetResp[ISTSLA]);                            
                            }
                        }//for
                        // console.log('Cancelled one : --> '+JSON.stringify(cancelledSLAs)); 
                        component.set("v.Cancelled_SLAs",cancelledSLAs);
                        component.set("v.Cancelled_SLAs_size",cancelledSLAs.length);
                    }//else
                    
                    
                    //END Business Logic    
                    resolve(IncidentServicetargetResp);                     
                }//if( state === "SUCCESS")
                else if(state == "ERROR")
                {
                    var errors = resp.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject(Error("Error message: " + errors[0].message));
                        }
                    }
                    else
                    {
                        reject(Error("unknown Error"));
                    }//
                }//else if(state == "ERROR")
            });
            $A.enqueueAction(IncidentServicetarget);
            
        });//promise End     
    },
    
    
})