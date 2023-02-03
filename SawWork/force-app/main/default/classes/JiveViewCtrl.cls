/**
    * @Author- Persistent
    * @Description-Custom Controller class ,used in  caseThreads visualforce page  
    */
public with sharing class JiveViewCtrl extends JivePaginationUtil{
public Case aCase {get; private set;}
String caseId ;
//subject of the case created from Jive Community .Used in caseThreads Page
public String caseSubject {get; private set;}
private final Case cse;
//List of all discussion replies
public List<JiveViewThreadResponseWrapper> threadItems{get{return (threadItems!=null) ? threadItems : new List<JiveViewThreadResponseWrapper>();}set;}
public List<SelectOption> pageLst
{
        get
        {
                pageLst = new List<SelectOption>();
                pageLst.add(new SelectOption('5','5'));
                pageLst.add(new SelectOption('10','10'));
                return pageLst;
        }
        set;
} 


/**
    * @Author- Persistent
    * @Description-Custom controller constructor.Initializes caseId and caseSubject
    */
public JiveViewCtrl(ApexPages.StandardController  stdController) {

    this.cse = (Case)stdController.getRecord();
    caseId = cse.Id; 
    caseSubject=cse.subject;
    pageSize=5;
    try{
      if(caseSubject.length()>200){
                     caseSubject.substring(0,200);
                     caseSubject=caseSubject+'...'; 
                     system.debug('caseSubject'+caseSubject);
                     
      }               
    system.debug('caseSubject'+caseSubject);
    }catch(Exception Ex){
         system.debug('Exception in JiveViewCtrl constructor');
    }
}//constructor ends


/**
    * @Author- Persistent
    * @Description-This method is used calulate the total number of pages based on the no. case threads and selected pagesize
    */
public void checkIfPageSizeChanged() {
    try{
    pageCountCon = Integer.valueOf(Math.ceil(Decimal.valueOf(threadItems.size())/pageSize)); //force Decimal division as opposed to integer division
    currentConPage = 1;
    }catch(Exception Ex){
        system.debug('Exception in checkIfPageSizeChanged');
    }
 
 }



/**
    * @Author- Persistent
    * @Description-This method calls the Addon Endpoint to retrieve all discussion replies. 
    */
 public PageReference retrieveCaseThreads () {
    
    try{
    
      aCase=[SELECT Content_ID__c,Id FROM Case
                  WHERE Id =:caseId];
                  
    system.debug(aCase);
    String jsonResponse='';
    if(!Test.isRunningTest()){
    //Calling Addon REST Api to retrieve all replies of discussion in Jive Community.
    //aCase.Content_ID__c is the Content Id of the discussion from which SFDC Case is created   
    HTTPResponse jiveHttpResponse= JiveAPIUtil.retrieveCaseThreads(aCase.Content_ID__c);
    system.debug('jiveHttpResponse--'+jiveHttpResponse);
    if(jiveHttpResponse != null && String.isNotBlank(jiveHttpResponse.getBody())){
        jsonResponse = jiveHttpResponse.getBody();
        system.debug('jsonResponse-'+jsonResponse);
    }
    }
   else
   {
        jsonResponse='[{"subject":"Re: is this showing the escalate link","description":"reply to my questionGreaterThan200CharactersGreaterThan200CharactersGreaterThan200CharactersGreaterThan200CharactersGreaterThan200CharactersGreaterThan200CharactersGreaterThan200CharactersGreaterThan200CharactersGreaterThan200CharactersGreaterThan200Characters","contentUpdatedOn": "2014-03-12T06:52:41.603+0000","replyURL":"https://jivedemo-cloudsquads.jiveon.com/message/2141#2141","isChildReply":false,"author": "Ratnesh Kurulkar"},{"subject": "Re: is this showing the escalate link","description": "2nd level reply to the question","contentUpdatedOn": "2014-03-12T06:53:22.761+0000","replyURL": "https://jivedemo-cloudsquads.jiveon.com/message/2142#2142","isChildReply": true,"author": "Ratnesh Kurulkar"}]'; 
   }
   threadItems = (List<JiveViewThreadResponseWrapper>)JSON.deserialize(jsonResponse,List<JiveViewThreadResponseWrapper>.class); 
       for(JiveViewThreadResponseWrapper thread:threadItems){
                 if(thread.description!=NULL && thread.description.length()>200){
                     thread.description=thread.description.substring(0,200);
                     thread.description=thread.description+'...';
                     system.debug('truncated description'+thread.description);
                 }
      
       }
       system.debug('threadItems--'+threadItems);
       //calculating the number of pages to be displayed
       pageCountCon=Integer.valueOf(Math.ceil(Decimal.valueOf(threadItems.size())/pageSize));
    }
    catch(Exception ex){
        system.debug('Exception inside JiveViewCtrl--'+ex.getMessage());
    } 
   return NULL;
    
}//retrieveCaseThreads  ends
  /**
    * @Author- Persistent
    * @Description-Wrapper class for Response from Addon 
    */
public class JiveViewThreadResponseWrapper {
    public String subject{get;set;}
    public String author{get;set;}
    public String description{get;set;}
    //Url of jive reply 
    public String replyURL{get;set;}
    public Date contentUpdatedDate{get{ return date.valueOf(contentUpdatedOn);}set;}
    public String contentUpdatedOn{get;set;}
    //this is not used....remove this(check once) 
    public Boolean isChildReply{get;set;}
    
}//JiveViewThreadResponseWrapper ends

}//JiveViewCtrl ends