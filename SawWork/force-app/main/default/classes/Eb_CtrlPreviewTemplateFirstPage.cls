/*
AUTHOR:SAMIR JHA
Release 3.24:CR 1766819 - CNotify: Rel: 3.24 Preview at Mailer Creation Wizard Page 1
Controller class for the Page PreviewTemplateFirstPage which facilitates the preview of selected template on the first page.
*/
public class Eb_CtrlPreviewTemplateFirstPage
{  
    public String subject{get;set;}
    public String body{get;set;}
    public string HTMLValue{get;set;}
    public List<String> bodyWithLineBreaks{get;set;}
    public String contactId;
    public string HeaderImageUrl{get;set;}
    public string FooterImageUrl{get;set;}
    public Boolean renderHTML{get;set;}
    public Boolean renderText{get;set;}
    public Id templateId;
    public Id letterId;
    public string EB_TemplatePreviewUrl{get;set;}
    public string LetterheadURL{get;set;}
    public BrandTemplate letterhead;
    public string letterHTMLValue{get;set;}
    public EmailTemplate emailTemplate;
    public EB_Token__c tokenParameters;
    string parentToken;
    //Constructor for Eb_CtrlPreviewTemplateFirstPage
    public Eb_CtrlPreviewTemplateFirstPage()
    
    {
        parentToken= ApexPages.currentPage().getParameters().get('token');

         tokenParameters = [select EB_ChatterNotification__c,EB_TokenEmailTemplate__c,EB_TokenEmailTemplate__r.Id,EB_TokenAdditionalReason__c,EB_TokenIssueReason__c,EB_TokenImpactedProduct__c,EB_TokenImpactedRegion__c,EB_TokenEndDate__c,EB_TokenStartDate__c,EB_TokenSINumber__c from EB_Token__c where Id =:parentToken];
         templateId=ApexPages.currentPage().getParameters().get('templateidParam');
         
         if(templateId!= NULL)
         {
             try
                 {
                    emailTemplate =[select id,name,subject, body ,BRANDTEMPLATEID,HtmlValue,TEMPLATETYPE from EmailTemplate where id =:templateId];
                 }
             catch(exception exp)
                 {
                   EB_EmailTemplate__c emailTemplateCN=[select id,EB_SFEmailTemplateId__c from EB_EmailTemplate__c where id=:templateId][0] ;
                   templateId=emailTemplateCN.EB_SFEmailTemplateId__c;
                   if(templateId!= NULL)
                     { 
                     
                     emailTemplate =[select id,name,subject, body ,BRANDTEMPLATEID,HtmlValue,TEMPLATETYPE from EmailTemplate where id =:templateId];
                     }
                 
                 }
         }
         if(emailTemplate!=null && emailTemplate.TEMPLATETYPE!='text')
            {    
                 
                Integer index1,Lastindex,index2,i,j;
                renderHTML=true;
                renderText=false;
                letterId=emailTemplate.BRANDTEMPLATEID;
               
                subject = emailTemplate.subject;
                HTMLValue=emailTemplate.HtmlValue;
                HtmlValue=substitute(HtmlValue,parentToken);
               
                HtmlValue=HtmlValue.replaceall(']]>','');
                HtmlValue=Contactsubstitute(HtmlValue);
                
                letterhead=[select id,value from BrandTemplate where Id = :letterId];
                
                letterHTMLValue=letterhead.value;
               
                try
                {
                    if(letterHTMLValue.containsNone('https://akamai--'))
                    //Contains Neither Header nor Footer Image  
                        {
                        HeaderImageUrl=NULL;
                        FooterImageUrl=NULL;
                                            
                        }
                    else if(letterHTMLValue.countMatches('https://akamai--')==1)
                    //Contains either Header or Footer image
                    {
                            index1=letterHTMLValue.indexOf('https://akamai--');

                            i=index1;
                            j=0;
                            while((letterHTMLValue.substring(i,i+1))!=']')
                            {

                                    i++;


                            }
                            //Contains only header
                            if((letterHTMLValue.indexOf('headerImage')<letterHTMLValue.indexOf('https://akamai--') && (letterHTMLValue.indexOf('https://akamai--')<(letterHTMLValue.indexOf('footerImage')))))
                            {

                                    HeaderImageUrl=letterHTMLValue.substring(index1,i); 
                                    FooterImageUrl=NULL;
                            }
                            //Contains only footer image
                            else if((letterHTMLValue.indexOf('https://akamai--')>(letterHTMLValue.indexOf('footerImage'))))
                            {
                                    FooterImageUrl=letterHTMLValue.substring(index1,i);
                                    HeaderImageUrl=NULL;
                            }

                    }
                    //Contains both Header and Footer
                    else if(letterHTMLValue.countMatches('https://akamai--')>1)
                    {
                        index1=letterHTMLValue.indexOf('https://akamai--');

                        i=index1;
                        j=0;
                        while((letterHTMLValue.substring(i,i+1))!=']')
                        {
                                i++;
                        }
                        HeaderImageUrl=letterHTMLValue.substring(index1,i); 

                        Lastindex=i;
                        index2=letterHTMLValue.indexOf('https://akamai--',i);

                        i=index2;
                        j=0;
                        while((letterHTMLValue.substring(i,i+1))!=']')
                        {
                                i++;
                        }
                        FooterImageUrl=letterHTMLValue.substring(index2,i);

                    }
                }
                catch(exception e)
                {
                        HeaderImageUrl=Null;
                        FooterImageUrl=Null;
                }



      }
            //It is a text template
            else
            {   
                renderText=true;
                subject = emailTemplate.subject;
                body = emailTemplate.body;
              
                body=substitute(body,parentToken);
                body=Contactsubstitute(body);
                bodyWithLineBreaks = body.split('\n');
            }
     
     
    }
    /*
    Release 3.24:CR 1766819 - CNotify: Rel: 3.24 Preview at Mailer Creation Wizard Page 1
    AUTHOR:SAMIR JHA
    This function substitues the merge fields in the selected email template with the values in the token object.
    Also if the value for merge field is not found,just replaces the merge field with the label of the field.
    */
   public String substitute(String emailBody,String token) 
   {
            String tokenId=token;
            List<String> objects = new List<String>();
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            Map<String, String> fieldsValues = new Map<String,String>{}; 
            objects.add('EB_AkaMContact__c');
            objects.add('EB_AkaMailer__c');
            Schema.SObjectType objToken = gd.get('EB_Token__c') ;
            Schema.SObjectType objMailer = gd.get('EB_AkaMailer__c') ;
            Schema.SObjectType objMailercontact = gd.get('EB_AkaMContact__c') ;
            Map<String, Schema.SObjectField> MapToken = objToken.getDescribe().fields.getMap() ;
            Map<String, Schema.SObjectField> MapMailer = objMailer.getDescribe().fields.getMap() ;
            Map<String, Schema.SObjectField> MapMailercontact = objMailercontact.getDescribe().fields.getMap();
            String objFields = '';
            String objFieldLabels = '';
            Map<String, String> fieldsMapping = new Map<String,String>{}; 
            for (Schema.SObjectField fieldToken : MapToken.values())
            {
                for (Schema.SObjectField fieldMailer : MapMailer.values())
                {
                        String fieldnameToken = fieldToken.getDescribe().getName();
                        String fieldnameMailer = fieldMailer.getDescribe().getName();
                        String fieldLabelToken = fieldToken.getDescribe().getlabel();
                        String fieldLabelMailer = fieldMailer.getDescribe().getlabel();
                        if(fieldLabelToken==fieldLabelMailer && fieldnameToken.contains('__c'))
                        {
                            fieldsMapping.put(fieldnameMailer,fieldnameToken);
                            objFields += fieldnameToken + ',';
                        }


                }
            }

            objFields = objFields.substring(0, objFields.lastIndexOf(',')); //trim last comma;

            System.debug('objFields: ' + objFields);  
            Sobject relObj;
            String qryString = 'SELECT ' + objFields + ' FROM EB_Token__c WHERE Id = '+'\''+tokenId+'\'';

            relObj = Database.query(qryString + ' limit 1');    

            list<string> fieldnamesMailer=new list<string>{'EB_AdditionalIssueDescription__c','EB_ChatterNotification__c','Email_Template__c','EB_ImpactedAkamaiProduct__c','EB_ImpactedRegion__c','EB_IssueEndDateTime__c','EB_IssueReason__c','EB_IssueStartDateTime__c','EB_SINumber__c'};

            for(String s : fieldnamesMailer) 
            {      

                try 
                {
                    if(fieldsMapping.get(s)!=null)
                    {
                        if (relObj.get(fieldsMapping.get(s)) != null)
                        {
                            fieldsValues.put('{!EB_AkaMailer__c.' + MapMailer.get(s).getDescribe().getName() + '}', String.valueOf(relObj.get(fieldsMapping.get(s))));
                        } 
                        else 
                        {

                            fieldsValues.put('{!EB_AkaMailer__c.' + MapMailer.get(s).getDescribe().getName() + '}', '<b>'+'< '+MapMailer.get(s).getDescribe().getLabel()+' >'+'</b>');
                        }
                    }
                } 
                catch(System.Exception e) 
                {
                    ApexPages.Message myMsg;                
                    myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());              
                    ApexPages.addMessage(myMsg);
                }
            }

            for(String s : fieldsValues.keySet()) 
            {
                if(emailBody.contains(s))
                {
                    emailBody = emailBody.replace(s, fieldsValues.get(s));
                }
            }

        return emailBody;
    }
    
    /*
    Release 3.24:CR 1766819 - CNotify: Rel: 3.24 Preview at Mailer Creation Wizard Page 1
    AUTHOR:SAMIR JHA
    This function substitues the merge fields from the Mailer Contact Object with dummy value in the selected email template.
    This needs to be done as the Accounts have not been selected in the first page.
    */
    
    public String Contactsubstitute(String emailBody)
    {
        String ContactBody= emailBody;
        Pattern MyPattern = Pattern.compile('\\{'+'.*'+'\\}');
        Matcher MyMatcher = MyPattern.matcher(ContactBody);
        String ContactLessBody = MyMatcher.replaceAll('< Account Name >');
        return ContactLessBody;
        
    }
    
}