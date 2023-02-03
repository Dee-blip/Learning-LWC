global class DummySwayer implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        //List<SawedLawg__c> sl= new List<SawedLawg__c>();
        List<String> resultinfo=new List<String>();
        //String clssname='';
        //String methodname='';
		//String Userid='';
        //String message1='';
        //String Stacktrace='';
        
       	String Subject= email.subject.toLowerCase();
        String s1='developer';
        String s2='flow';
        Boolean checkstrApex=Subject.contains(s1);
        Boolean checkstrFlow=Subject.contains(s2);
        try{
            Map<String,String> m1=new map<String,String>();
            String emailBody= '';
            
           	emailBody= email.plainTextBody;
        	if (checkstrApex==True){
                //Integer lenemailBody= emailBody.length();
                //print(emailBody)
                //List<String> lststring= emailBody.split('\n');
                //String lastline= lststring[-1];
                if(emailBody!=null && emailBody!=''){
                    //resultinfo.add(emailBody.substringBetween('Class.','#'));
                    //resultinfo.add(emailBody.substringBetween());
                    //resultinfo.add(emailBody.substringBetween('organization','/'));
                    m1.put('User_ID_Text__c',emailBody.substringBetween('organization','/'));
                    //m1.put('Class__c',emailBody.reverse().substringBetween('Class.','/'));
                    m1.put('Message_Text__c',emailBody.substringBetween('caused by: ','Class.'));
                    m1.put('Stack_Trace_Text__c',emailBody.substringBetween('Class.','#'));
                    //m1.put('User_ID_Text__c',emailBody.substringBetween('organization','/'));
                       
                    resultinfo.add(emailBody.substringBetween('caused by:','\n'));
                    resultinfo.add(emailBody.substringBetween('Class.','#'));
                   
             	}
                SawedLawg__c sL1= new SawedLawg__c();
                sL1.Class__c='newapexcall';
               	//sL1.Method__c=resultinfo[1];
                sL1.User_ID_Text__c=m1.get('User_ID_Text__c');
                sL1.Message_Text__c=m1.get('Message_Text__c');
                sL1.Stack_Trace_Text__c=m1.get('Stack_Trace_Text__c');
                insert sL1;
                //s1.add(sL1);
                
             
                
            }
            if(checkstrFlow==True)
            {
                if(emailBody!=null && emailBody!=''){
                    resultinfo.add(emailBody.substringBetween('Flow API Name:','Type:'));
                    //resultinfo.add(emailBody.substringBetween(open, close));
                    //resultinfo.add(emailBody.substringBetween(open, close));
                    resultinfo.add(emailBody.substringBetween('Error Occurred:','Salesforce Error ID:'));
                    resultinfo.add(emailBody.substringBetween('Flow Details','Error Occurred:')); 
                    
                }
                SawedLawg__c sL1= new SawedLawg__c();
                sL1.Class__c=resultinfo[0];
               	//sL1.Method__c=resultinfo[1];
                //sL1.User_ID_Text__c=resultinfo[2];
                sL1.Message_Text__c=resultinfo[3];
                sL1.Stack_Trace_Text__c=resultinfo[4]; 
                insert sL1;
                //s1.add(sL1);             
               
            }     
            result.success=True;
        }
        catch(Exception e){
                System.debug('error'+e.getMessage());
                 result.success=False;
            }
        //insert s1;
        return result;
        
    }
    
}