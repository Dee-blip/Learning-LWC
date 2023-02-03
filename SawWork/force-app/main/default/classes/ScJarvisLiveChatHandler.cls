/**
 * @description       : Jarvis LiveChatTranscript Handler
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 03-03-2022
 * @last modified by  : Vishnu Vardhan
 * @testlass          : ScJarvisLiveChatHandlerTest
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   01-23-2022   Vishnu Vardhan   Initial Version
**/
public class ScJarvisLiveChatHandler {
    // ESESP-6817	- ACC Duplicate Case Issue fix
    static final Map<String, Object> JARVIS_CHAT_FILTER = new Map<String, Object> {'Case_Origin__c' => 'AkaChat Community', 'CaseId' => null};

    /**
    * @description 
    * @author Vishnu Vardhan | 01-23-2022 
    * @param List<LiveChatTranscript> transcriptList 
    **/
    public static void createCasesForTranscripts(List<LiveChatTranscript> transcriptList) {

        List<LiveChatTranscript> jarvisChats = SC_Utility.filterSObjList(transcriptList, JARVIS_CHAT_FILTER);

        if(transcriptList.isEmpty()) {
            return;
        }
         
        Map<Id, Case> chatCaseMap = new Map<Id, Case>();
        for(LiveChatTranscript lt: jarvisChats) {
            List<Account> accList = [select id from account where id = :lt.AccountId for update];
            if(lt.CaseId == null) {
                Case cs = new Case(
                    AccountId = lt.AccountId,
                    ContactId = lt.ContactId, 
                    Subject = lt.Case_Subject__c,
                    Description = lt.Case_Description__c,
                    Origin = lt.Case_Origin__c,
                    Case_Product__c = lt.Case_Product_Id__c,
                    RecordTypeId = lt.Case_Record_Type__c,
                    //Request_Type__c = lt.Case_Request_Type__c,
                    //Service__c = lt.Case_Service__c,
                    Do_Not_Show_In_Portal_Picklist__c  = 'Customer', //lt.Case_Visibility__c,
                    Validation_Override__c = true
                	);
            	chatCaseMap.put(lt.Id, cs);
            }
        }
        try {
            insert chatCaseMap.values();
        } Catch(Exception ex) {
            SC_Jarvis_utility.sendErrorMails('Jarvis Create Case For Chat','Exception: ' , ex.getMessage());
            jarvisChats[0].Case_Description__c = Userinfo.getProfileId() + ' -- ' + ex.getMessage();
        }
        for(LiveChatTranscript lt: jarvisChats) {
            if(lt.CaseId == null) {
                lt.CaseId = chatCaseMap.get(lt.Id).Id;
            }
        }
        
    }
}