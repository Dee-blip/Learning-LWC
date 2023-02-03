({
    doInit: function(component, event, helper) {
        console.log("Entering doInit Function" + "cmp:InternalEmailFeed");
        var recordId = component.get("v.recordId");
        var action = component.get("c.getEmail");
        action.setParams({
            recordId: recordId
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var result = response.getReturnValue();
                //console.log(JSON.stringify(response.getReturnValue()));
                if(result.length == 0)
                {
                    component.set("v.EmailContent", false);
                    component.set("v.ErrorContent", true);
                }
                else
                {
                    component.set("v.EmailContent", true);
                    component.set("v.ErrorContent", false);
                }
                
                var firstvariable = "<html>";
                var secondvariable = "</html>";
                //Looping through record
                /** for(var i=0;result.length;i++)
        {
            console.log(JSON.stringify(result[i].HtmlBody));
            var htmlbody = JSON.stringify(result[i].HtmlBody);
            var htmlbodyfinal = htmlbody.split('<html>').pop().split('</html>').shift();
            result[i].HtmlBody = @Html.Raw(htmlbodyfinal.ToJson());
        } **/
                
                //alert(result.TextBody);
                //alert('Returned List'+myopenlst);
                component.set("v.EmailList", result);
            }
        });
        $A.enqueueAction(action);
        console.log("Exiting doInit Function" + "cmp:InternalEmailFeed");
    },
    
    navigateEmail: function(component, event, helper) {
        console.log("Entering navigateEmail Function" + "cmp:InternalEmailFeed");
        
        
        var emailid2 = event.target.id;
        
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            recordId: emailid2,
            
        });
        navEvt.fire();
        console.log("Exiting navigateEmail Function" + "cmp:InternalEmailFeed");
    },
    
    closesection: function(component, event, helper)
    {
        console.log("Entering closesection Function" + "cmp:InternalEmailFeed");
        /***Getting relevant dom in iteration***/
        var selectedItem = event.currentTarget;
        var id = selectedItem.dataset.id;
        var Elements = component.find('testli');
        var Elements2 = component.find('subEle');
        
        /**Method to get Object Length since it returns undefined if only one element is There**/
        var ElementsLength = helper.getLength(Elements);
        var Elements2Length = helper.getLength(Elements2);
        
        /*** If else block to differentiate operation when only one element is there vs multiple
         elements in Iteration ***/
        if(ElementsLength===1)
        {
            $A.util.toggleClass(Elements, "slds-hide");
            $A.util.toggleClass(Elements2, "slds-hide");
        }
        
        else
        {
            for (var i = 0; i < ElementsLength; i++) {
                var val = Elements[i].getElement().getAttribute('data-id');
                
                if(val===id)
                {
                    $A.util.toggleClass(Elements[i], "slds-hide");
                }
                
                
            }
            for (var i = 0; i < Elements2Length; i++) {
                var val = Elements2[i].getElement().getAttribute('data-id');
                
                if(val===id)
                {
                    $A.util.toggleClass(Elements2[i], "slds-hide");
                }
                
                
            }
            
            
        }
        
        
        console.log("Exiting closesection Function" + "cmp:InternalEmailFeed");
        
    },
    
    ReplyHandler: function(component, event, helper)
    {
        console.log("Entering ReplyHandler Function" + "cmp:InternalEmailFeed");
        //Get Email value from target
        var target = event.getSource(); 
        var Email = target.get("v.value") ;
        //console.log('Email'+Email)
        
        //Get Passed Email Values
        var ToAddress=Email.ToAddress;
        var FromAddress= Email.FromAddress;
        var MessageDate = Email.MessageDate;
        var Subject = Email.Subject;
        var FromName=Email.FromName;
        
        //Construct Email message to append to keep look and feel like Salesforce default reply
        var ToAddress1 = ToAddress.split(";");
        var Subject = Email.Subject;
        var HtmlBody = Email.HtmlBody;
        var HtmlBody2= HtmlBody.split('<html>').pop().split('</html>').shift();
        var string1= '<br clear="none">--------------- Original Message ---------------<br clear="none">';
        var FromAddressString='<b>From: </b>'+FromName+'['+FromAddress+']'+ '<br clear="none">';
        var MessageDateString='<b>Sent: </b>'+MessageDate+ '<br clear="none">';
        var ToAddressString  ='<b>To: </b>'+ToAddress+ '<br clear="none">';
        var SubjectString    ='<b>Subject: </b>'+Subject+ '<br clear="none">'; 
        var string1=string1+FromAddressString+MessageDateString+ToAddressString+SubjectString;
        
        var finalHtml= string1.concat(HtmlBody2);
        
        /******* Quick Action Api Piece ******/
        var actionAPI = component.find("qaAPI");
        //Assign Quick Action field values
        var fields = {ToAddress:{value :ToAddress1},
                      Subject:{value:Subject},
                      CcAddress:{value:""},
                      BccAddress:{value:""},
                      HtmlBody:{value:finalHtml}
                      
                      
                      
                      
                     };
        //Quick Action with target field values
        var args = {actionName: "Case.Send_Email_SOCC", entityName: "Case", targetFields: fields};
        actionAPI.setActionFieldValues(args);
        /******* Quick Action Api Piece Ends ******/
        console.log("Exiting ReplyHandler Function" + "cmp:InternalEmailFeed");
        
        
    }
    
});