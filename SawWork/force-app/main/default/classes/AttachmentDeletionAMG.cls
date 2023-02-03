/* Class Created For ESESP-1916 to prevent deletion of attachment for Closed AMG Migration Cases 
   Created By: Sumanth S Naik 26/2/2019
*/


public class AttachmentDeletionAMG
{
    public static void preventAttachmentDelAMG(List<Attachment> AttachList)
    {
    
         //Get Prefix for Case
          Map<String, Schema.SObjectType> m  = Schema.getGlobalDescribe() ;
          Schema.SObjectType s = m.get('Case') ;
          Schema.DescribeSObjectResult r = s.getDescribe() ;
          String testObjectPrefix = r.getKeyPrefix();
          
          //Getting all Case Records
          Set <Id> CaseRecords = new Set <Id>();  
          
          //Create a Map of Attachment Parent Id - Attachment
          Map<Id,Attachment> parentIdAttachment = new Map<Id,Attachment>();
          
          for(Attachment A:AttachList)
          {
          
               if(String.ValueOf(A.ParentId).startsWith(testObjectPrefix))
               {
               
                     CaseRecords.add(A.ParentId);
                     parentIdAttachment.put(A.ParentId,A);
               
               }
          
          
          } 
          
          
          //Querying all Case Records which are closed and RecType = AMG
          
          List<Case> EligibleCaseRec = [Select Id,Service__c, Request_Type__c, Request_Sub_Type__c from Case where Status='Closed' and RecordType.Name='AMG' and id in :CaseRecords];
          
          //Create a Map of Case Id,Case Rec
          Map<Id,Case> IdCaseMap = new Map<Id,Case>();
          
          for(Case C:EligibleCaseRec)
          {
                 if((C.Service__c=='Contract Management' && C.Request_Type__c=='Contract Migration' && C.Request_Sub_Type__c=='Migration') ||
                          (C.Service__c=='Contract Management' && C.Request_Type__c=='Service Migration' && C.Request_Sub_Type__c=='Migration'))
                          
                          
                 {         
                          
                
                IdCaseMap.put(C.Id,C);
                
                
                 }
                 
          }
          
          
          for(Attachment A:AttachList)
          {
          
                 if(IdCaseMap.get(A.ParentId)!=null && (A.Name.endsWithIgnoreCase('.xls') || A.Name.endsWithIgnoreCase('.xlsx')))
                 {
                 
                        A.addError('A file cannot be deleted from a closed case');
                 }
          
          
          }
    }
}