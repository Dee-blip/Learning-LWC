/*
Author          : Sharath P / Sumukh SS
Description     : Controller for JARVIS Case Create / Detail Pages

WARNING : THIS IS A CUSTOMER FACING APEX CLASS. PLEASE PERFORM ALL CODE REVIEWS WITH REQUIRED TEAM MEMBERS BEFORE
DEPLOYING CODE TO PRODUCTION.

Date                    Developer             		JIRA #                      Description                                                       
--------------------------------------------------------------------------------------------------------------------------------
25 Jan 2021				Authors				 	    					  		Initial Development
01 Dec 2021				Harshil						ESESP-6070					Check #days since case closed to disable edit
12 Dec 2021				Harshil						ESESP-6277					Added Last_Case_Update__c Update to current date
19 Jan 2021				Harshil						ESESP-6568					Disable Edit and Clone access for PTS Cases
4 April 2022            Sharath                     ESESP-7013                  Severity for Riverbed AMG, Billing
06 Jun 2022				Vamsee						ESESP-7043					Parent Account field for AMG & Billing
--------------------------------------------------------------------------------------------------------------------------------
*/

public without sharing class SC_Jarvis_Create_Case_Controller 
{

    public static Id userId = UserInfo.getUserId();
    public static Id contactId; 
    public static Id contactAccountId; 
    public static String technicalAccessString = 'CASE_MANAGEMENT_WRITE';
    public static String psAccessString = 'CASE_MANAGEMENT_WRITE;CASE_MANAGEMENT_PS_ACCESS';
    public static Case caseRecordForClone;
    public static Boolean hasCurrentRecordAccess;
    static
    {
        User userRec =[select contactId,contact.AccountId,akam_user_id__c from User where Id = :userId limit 1];
        if(userRec.contactId != null)
        {
            contactId = userRec.contactId;
            contactAccountId = userRec.contact.AccountId;
        }
        else
        {
            List<Contact> contactRec = [Select Id,AccountId from contact where akam_contact_id__c = :userRec.akam_user_id__c 
            and active_portal_login__c = true limit 1];
            if(contactRec.size() == 1)
            {
                contactId = contactRec.get(0).Id;
                contactAccountId = contactRec.get(0).AccountId;
    
            }
        }
    }

    public SC_Jarvis_Create_Case_Controller() 
    {

    }
    public class CaseCreateWrapper
    {
        @AuraEnabled public List<Account> accounts{get;set;}
        @AuraEnabled public Set<Account> parentAccounts{get;set;}
        @AuraEnabled public SC_Select_Options_Wrapper categories{get;set;}
        @AuraEnabled public SC_Select_Options_Wrapper policyDomains{get;set;}
        @AuraEnabled public SC_Select_Options_Wrapper products{get;set;}
        @AuraEnabled public SC_Select_Options_Wrapper problems{get;set;}
        @AuraEnabled public SC_Select_Options_Wrapper severity{get;set;}
        @AuraEnabled public String loggedInContact{get;set;}
        @AuraEnabled public Boolean isReseller{get;set;}
        @AuraEnabled public List<QuestionWrapper> questions{get;set;}
        @AuraEnabled public SearchWrapper searchResults{get;set;}
        public CaseCreateWrapper()
        {
            isReseller=false;
        }
    }
    public class CaseDetailWrapper
    {
        @AuraEnabled public Case caseRecord{get;set;}
        @AuraEnabled public Boolean hasEditAccess{get;set;}
        @AuraEnabled public Boolean isReseller{get;set;}
        @AuraEnabled public String severity{get;set;}
        //ESESP-6568: added RT and subtype to wrapper
        @AuraEnabled public String recordType{get;set;}
        @AuraEnabled public String subType{get;set;}
        @AuraEnabled public String statusValue{get;set;} 
        @AuraEnabled public String createdDate{get;set;} 
        public CaseDetailWrapper(Case record, Boolean access, String severityValue, String statusValue, String createdDateValue, 
        String recordTypeName, String subTypeName)
        {
            caseRecord = record;
            hasEditAccess = access;
            severity = severityValue;
            this.statusValue = statusValue;
            isReseller = false;
            createdDate = createdDateValue;
            recordType = recordTypeName;
            subType = subTypeName;
        }
    }

    public class QuestionWrapper
    {
        @AuraEnabled public String helpText{get;set;}
        @AuraEnabled public String question{get;set;}
        @AuraEnabled public String questionType{get;set;}
        @AuraEnabled public String recordId{get;set;}
        @AuraEnabled public Boolean required{get;set;}
        @AuraEnabled public Boolean textArea{get;set;}
        @AuraEnabled public Boolean urlType{get;set;}
        @AuraEnabled public Boolean nonText{get;set;}
        @AuraEnabled public List<SC_Select_Options> options{get;set;}
        @AuraEnabled public String response{get;set;}
        @AuraEnabled public String placeHolder{get;set;}

        public QuestionWrapper(String recordIdValue,String questionValue, String type, String helpTextValue, Boolean requiredValue)
        {
            recordId = recordIdValue;
            helpText = helpTextValue;
            question = questionValue;
            questionType = type;
            required = requiredValue;
            textArea = questionType == 'Text'? true: false;
            urlType = questionType == 'URL' ? true : false;
            nonText = questionType != 'Text' && questionType != 'Picklist' && questionType != 'URL'? true: false;
            placeHolder = questionType == 'URL' ? 'https://abc.akamai.com' : '';
            response = '';
        }
    }

    public class KnowledgeWrapper
    {
        @AuraEnabled public String title{get;set;}
        @AuraEnabled public String summary{get;set;}
        @AuraEnabled public String akamId{get;set;}
        @AuraEnabled public String recordId{get;set;}
        @AuraEnabled public Integer viewCount{get;set;}
        @AuraEnabled public DateTime publishedDate{get;set;}

        public KnowledgeWrapper(String titleString,String summaryString, String akamIdValue, 
        String recordIdValue,Integer viewCount)
        {
            title = titleString;
            summary = summaryString;
            akamId = akamIdValue;
            recordId = recordIdValue;
            this.viewCount = viewCount;
        }
    }
    
    public class DiscussionWrapper
    {
        @AuraEnabled public String title{get;set;}
        @AuraEnabled public String recordId{get;set;}
        @AuraEnabled public Integer commentCount{get;set;}
        @AuraEnabled public DateTime postedDate{get;set;}
        @AuraEnabled public Boolean isAnswered{get;set;}

        public DiscussionWrapper(String titleString, String recordIdValue, Integer commentCount,
        Boolean isAnswered)
        {
            title = titleString;
            recordId = recordIdValue;
            this.commentCount = commentCount;
            this.isAnswered = isAnswered;
        }
    }

    public class SearchWrapper
    {
        @AuraEnabled public List<DiscussionWrapper> questions{get;set;}
        @AuraEnabled public List<KnowledgeWrapper> articles{get;set;}

    }
    public class ArticleVoteWrapper
    {
        @AuraEnabled public Knowledge__kav articleRecord{get;set;}
        @AuraEnabled public String vote{get;set;}
    }


    @AuraEnabled
    public static SearchWrapper getKnowledgeDiscussion(String subject, String caseProduct)
    {
        SearchWrapper searchWrapperVar = new SearchWrapper();

        List<list<SObject>> searchList = new List<list<SObject>>();
        List<Knowledge__kav> knowledgeList = new List<Knowledge__kav>();
        List<FeedItem> feedList = new List<FeedItem>();
        String searchObject;
        Integer articleIndex;
        Integer feedIndex;
        if(subject != null && subject.length() >= 3 && caseProduct != null && caseProduct.length() >= 3)
        {
            searchList = SC_Jarvis_Search_Controller.searchKnowledge(subject, caseProduct,'Both');
            
            articleIndex = searchList != null && 
            (searchList.size() == 2 || String.valueOf(searchList[0].getSObjectType()) == 'Knowledge__kav') ?
            0 : -1;

            feedIndex = searchList != null && searchList.size() == 2 ? 1 : 
            searchList != null && String.valueOf(searchList[0].getSObjectType()) != 'Knowledge__kav' ? 0 : -1;

            if(articleIndex != -1)
            {
                knowledgeList.addAll((List<Knowledge__kav>)searchList[articleIndex]);
            }
            if(feedIndex != -1)
            {
                feedList.addAll((List<FeedItem>)searchList[feedIndex]);
            }    

            //system.debug('subject1: ' + searchList);
        }
        if(subject != null && subject.length() >= 3 && (knowledgeList.size() != 5 || feedList.size() != 5))
        {
            searchObject = knowledgeList.size() != 5 && feedList.size() != 5 ? 'Both':
            knowledgeList.size() != 5? 'Article' : 'Feed';
            searchList = SC_Jarvis_Search_Controller.searchKnowledge(subject, null,searchObject);
            
            articleIndex = searchList != null && 
            (searchList.size() == 2 || String.valueOf(searchList[0].getSObjectType()) == 'Knowledge__kav') ?
            0 : -1;

            feedIndex = searchList != null && searchList.size() == 2 ? 1 : 
            searchList != null && String.valueOf(searchList[0].getSObjectType()) != 'Knowledge__kav' ? 0 : -1;

            if(articleIndex != -1)
            {
                knowledgeList.addAll((List<Knowledge__kav>)searchList[articleIndex]);
            }
            if(feedIndex != -1)
            {
                feedList.addAll((List<FeedItem>)searchList[feedIndex]);
            }    
        }
        if(caseProduct != null && caseProduct.length() >= 3 && (knowledgeList.size() != 5 || feedList.size() != 5))
        {
            searchObject = knowledgeList.size() != 5 && feedList.size() != 5 ? 'Both':
            knowledgeList.size() != 5? 'Article' : 'Feed';

            searchList = SC_Jarvis_Search_Controller.searchKnowledge(null, caseProduct,searchObject);
            
            articleIndex = searchList != null && 
            (searchList.size() == 2 || String.valueOf(searchList[0].getSObjectType()) == 'Knowledge__kav') ?
            0 : -1;

            feedIndex = searchList != null && searchList.size() == 2 ? 1 : 
            searchList != null && String.valueOf(searchList[0].getSObjectType()) != 'Knowledge__kav' ? 0 : -1;

            if(articleIndex != -1)
            {
                knowledgeList.addAll((List<Knowledge__kav>)searchList[articleIndex]);
            }
            if(feedIndex != -1)
            {
                feedList.addAll((List<FeedItem>)searchList[feedIndex]);
            }    
        }

        //List<Knowledge__kav> articles = SC_Jarvis_utility.searchKnowledge(searchString);
        List<KnowledgeWrapper> wrappers = new List<KnowledgeWrapper>();
        KnowledgeWrapper articleWrapper;

        for(Knowledge__kav article : knowledgeList)
        {
            articleWrapper = new KnowledgeWrapper(article.Title, article.Summary,article.AKAM_Article_Number__c,article.Id,
            article.ArticleTotalViewCount);
            wrappers.add(articleWrapper);        
            if(wrappers.size() == 5)
            {
                break;
            }    
        }
        searchWrapperVar.articles = wrappers;


        //List<FeedItem> discussions = SC_Jarvis_utility.searchDisussion(searchString);
        List<DiscussionWrapper> discussionWrappers = new List<DiscussionWrapper>();
        DiscussionWrapper discussionWrapper;
        Boolean answeredValue;
        for(FeedItem question : feedList)
        {
            answeredValue = question.BestCommentId != null ? true: false;
            discussionWrapper = new DiscussionWrapper(question.Title, question.Id,question.CommentCount,answeredValue);
            discussionWrappers.add(discussionWrapper);      
            if(discussionWrappers.size() == 5)
            {
                break;
            }    

        }
        searchWrapperVar.questions = discussionWrappers;
        return searchWrapperVar;
    }

    @AuraEnabled(cacheable=true)
    public static ArticleVoteWrapper getArticleData (String articleId)
    {
        ArticleVoteWrapper articleWrapper = new ArticleVoteWrapper();
        articleWrapper.articleRecord = SC_Jarvis_utility.getArticle(articleId);

        Vote voteRec = SC_Jarvis_utility.getVoteRec(articleWrapper.articleRecord.KnowledgeArticleid,UserInfo.getUserId());
        articleWrapper.vote = voteRec != null ? voteRec.Type : 'None';
        return articleWrapper;
    }

    @AuraEnabled
    public static String saveVote (String articleId, String vote)
    {
        Knowledge__kav articleRec = SC_Jarvis_utility.getArticle(articleId);
        Vote voteRec = SC_Jarvis_utility.getVoteRec(articleRec.KnowledgeArticleid,UserInfo.getUserId());
        if(voteRec == null)
        {   
            voteRec = new Vote();
            voteRec.Type = vote;
            voteRec.parentId = articleRec.KnowledgeArticleid;
            try 
            {
                insert voteRec;    
            } 
            catch (Exception e) 
            {
                SC_Jarvis_utility.sendErrorMails('Jarvis Vote Record Insert Error','Exception: ' , e.getMessage());
            }
            
        }
        else
        {
            if(vote == 'None')
            {
                try 
                {
                    delete voteRec;
                } 
                catch (Exception e) 
                {
                    SC_Jarvis_utility.sendErrorMails('Jarvis Vote Record Delete Error','Exception: ' , e.getMessage());
                }
    
            }
            else
            {
                voteRec.Type = vote;
                try 
                {
                    update voteRec;    
                } 
                catch (Exception e) 
                {
                    SC_Jarvis_utility.sendErrorMails('Jarvis Vote Record Update Error','Exception: ' , e.getMessage());
                }
    
            }
        }  
        return 'Success';  
    }

    @AuraEnabled(cacheable=true)
    public static String getAccount(Boolean returnSet)
    {
        Set<Id> accountIds =  new Set<Id>();
        List<SC_Select_Options> accountSelectors = new List<SC_Select_Options>();
        CaseCreateWrapper createWrapper = new CaseCreateWrapper();
        createWrapper.accounts = SC_Jarvis_utility.getAccountRecords(contactId,'EditMode');
        createWrapper.loggedInContact = contactId;
        return JSON.serialize(createWrapper);
    }


    //Changes by Vamsee(ESESP-7043 - Sorry Page Issue)
    @AuraEnabled(cacheable=true)
    public static String getParentAccount(String accountId)
    {
        CaseCreateWrapper createWrapper = new CaseCreateWrapper();
        createWrapper.parentAccounts = SC_Jarvis_utility.getParentAccountRecords(contactId, accountId, contactAccountId);
        createWrapper.loggedInContact = contactId;
        return JSON.serialize(createWrapper);
    }

    
    @AuraEnabled(cacheable=true)
    public static CaseCreateWrapper getCategories(String accountId)
    {
        CaseCreateWrapper createWrapper = new CaseCreateWrapper();
        List<SC_Select_Options> categorySelectors = new List<SC_Select_Options>();
        List<Jarvis_Contact_ACC_Permission_Contract__c> contractPermissions = SC_Jarvis_utility.getPermissionRecords(contactId,accountId, SC_Jarvis_utility.getAccessSet('Write'),0);
        system.debug('contractPermissions: ' + contractPermissions);
        List<String> categorySet = new List<String>();
        if(contractPermissions.size() > 0)
        {   
            categorySet.add('Client Services Manager/ Business Support Issue');
            categorySet.add('Billing Support Issue or Question');

            Set<String> caseProducts = new Set<String>();
            
            set<String> techContracts = new set<String>();
            set<String> psContracts = new set<String>();

            set<String> techProducts = new set<String>();
            set<String> psProducts = new set<String>();

            set<String> techMarketingIds = new set<String>();
            set<String> psMarketingIds = new set<String>();

            Set<String> techAreas = new Set<String>();
            Set<String> psAreas = new Set<String>();

            for (Jarvis_Contact_ACC_Permission_Contract__c contractPermission : contractPermissions)
            {
                techContracts.add(contractPermission.Contract__c);
                if(contractPermission.Permission__c.contains('PS'))
                {
                    psContracts.add(contractPermission.Contract__c);
                }                    
            }
            if(techContracts.size() > 0)
            {
                if(SC_Jarvis_utility.getChildContracts(techContracts,1).size() == 1)
                {
                    createWrapper.isReseller = accountId != contactAccountId? false: true;
                }
                techAreas = SC_Jarvis_utility.getAreas('Technical');
                psAreas = SC_Jarvis_utility.getAreas('PS');
                for(Case_Product_Siebel_LOV__c siebelLOV: SC_Jarvis_utility.getLOVs(psAreas,accountId,null))
                {                
                    if(techAreas.contains(siebelLOV.Area__c))
                    {
                        techProducts.add(siebelLOV.Product__c);
                    }
                    if(psAreas.contains(siebelLOV.Area__c))
                    {
                        psProducts.add(siebelLOV.Product__c);
                    }
                    caseProducts.add(siebelLOV.Product__c);
                }
                if(caseProducts.size() > 0)
                {
                    for(Siebel_Marketing_Prod_Case_Prod_Map__c mappingRec: SC_Jarvis_utility.getMappingRecords(caseProducts,null))
                    {
                        if(techProducts != null && techProducts.size() > 0 &&
                        techProducts.contains(mappingRec.Case_Product_Name__c))
                        {
                            techMarketingIds.add(mappingRec.Marketing_Product_ID__c);
                        }
                        if(psProducts != null && psProducts.size() > 0 &&
                        psProducts.contains(mappingRec.Case_Product_Name__c))
                        {
                            psMarketingIds.add(mappingRec.Marketing_Product_ID__c);
                        }
                    }                
                    if(techMarketingIds.size() > 0 && 
                    SC_Jarvis_utility.getContractDetails(techContracts,techMarketingIds,new Set<String> {accountId},1).size() == 1)
                    {
                        categorySet.add('Technical Support Issue');
                    }
                    system.debug('techContracts: ' + techContracts);
                    if(psMarketingIds.size() > 0 && 
                    psContracts.size() > 0 && 
                    SC_Jarvis_utility.getContractDetails(psContracts,psMarketingIds,new Set<String> {accountId},1).size() == 1)
                    {
                        categorySet.add('Professional Services Request (billable)');
                    }
        
                }
    
            }
        } 

        if(SC_Jarvis_utility.getAuthorizedContact(contactId,1,new List<String>{accountId},null).size() == 1)
        {
            categorySet.add('Managed Security Support');
        }
        if(categorySet.size() > 0)
        {
            categorySet.sort();
        }
        for(String recordTypeString : categorySet)
        {
            categorySelectors.add(new SC_Select_Options(recordTypeString,SC_Jarvis_utility.getCategoryRecordType(recordTypeString)));
        }
        
        createWrapper.categories = new SC_Select_Options_Wrapper(categorySelectors, null);
        // system.debug('createWrapper.categories: ' + createWrapper.categories);        
        return createWrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static CaseCreateWrapper getPolicyDomains(String accountId)
    {
        CaseCreateWrapper createWrapper = new CaseCreateWrapper();
        List<SC_Select_Options> policyDomainSelectors = new List<SC_Select_Options>();
        Set<String> uniqueFilter = new Set<String>();

        for(Authorized_Contact__c authorizedContact: SC_Jarvis_utility.getAuthorizedContact(contactId,0,new List<String>{accountId},null))
        {
            if(!uniqueFilter.contains(authorizedContact.Policy_Domain__c))
            {
                uniqueFilter.add(authorizedContact.Policy_Domain__c);
                policyDomainSelectors.add(new SC_Select_Options(authorizedContact.Policy_Domain__r.Name,authorizedContact.Policy_Domain__c));                
            }
            
        }
        createWrapper.policyDomains = new SC_Select_Options_Wrapper(policyDomainSelectors,null);
        return createWrapper;
    }
 
    @AuraEnabled(cacheable=true)
    public static CaseCreateWrapper getProducts(String paramMap)
    {
        Map<String,String> param = (Map<String,String>) JSON.deserialize(paramMap,Map<String,String>.class);
        CaseCreateWrapper createWrapper = new CaseCreateWrapper();
        List<SC_Select_Options> productSelectors = new List<SC_Select_Options>();
        List<SC_Select_Options> serviceProducts;
        Set<String> uniqueFilter = new Set<String>();

        Boolean emergingProduct = false;
        Boolean carrierProduct = false;

        String accountId ;
        String category = '';
        if(param.containsKey('accountId') && param.containsKey('policyDomainId'))
        {           
            category = 'SOCC'; 
            String pdId = param.get('policyDomainId');
            accountId = param.get('accountId');
            system.debug('pdId: ' + pdId);
            for(Policy_Domain__c policyDomain: [Select Product__c,Additional_Product__c from Policy_Domain__c where id = :pdId order by Product__c])
            {
                if(policyDomain.Product__c != null)
                {
                    uniqueFilter.add(policyDomain.Product__c);  
                    productSelectors.add(new SC_Select_Options(policyDomain.Product__c,policyDomain.Product__c)); 
                    system.debug('productSelectors: ' + productSelectors);                               
                }
                if(policyDomain.Additional_Product__c != null)
                {
                    for(String productName: policyDomain.Additional_Product__c.split(';'))
                    {
                        if(!uniqueFilter.contains(productName))
                        {
                            uniqueFilter.add(productName);                                
                            productSelectors.add(new SC_Select_Options(productName,productName));
                            system.debug('productSelectors: ' + productSelectors);
                        }
                    }
                }
        
            }
            system.debug('uniqueFilter: ' + uniqueFilter);
        }
        else if(param.containsKey('accountId') && param.containsKey('category'))
        {
            category = param.get('category');
            accountId = param.get('accountId');
            Set<String> caseProducts = new Set<String>();
            if(category == 'Technical' || category == 'PS')
            {
                Set<String> permissions = new Set<String>();
                Set<String> contracts = new Set<String>();
                Set<String> originalContractIds = new Set<String>();      
                Set<String> marketingProducts = new Set<String> ();  
                
                if(category == 'Technical')
                {
                    permissions.add(technicalAccessString);
                }
                else
                {
                    permissions.add(psAccessString);
                }
                system.debug('Start Time: permission' + Datetime.now());
                for (Jarvis_Contact_ACC_Permission_Contract__c contractPermission : SC_Jarvis_utility.getPermissionRecords(contactId,accountId,permissions,0))
                {
                    contracts.add(contractPermission.Contract__c);
                    originalContractIds.add(contractPermission.Contract__r.Original_Contract_Id__c);
                }
                system.debug('End Time: permission' + Datetime.now());
                if(category == 'PS')
                {
                    serviceProducts = new List<SC_Select_Options>();
                    // system.debug('contracts: ' + contracts + ' accountId: ' + accountId );
                    system.debug('Start Time: Services' + Datetime.now());
                    String serviceString = SC_Jarvis_utility.getServicesPS(null,originalContractIds,null,0);
                    system.debug('End Time: Services' + Datetime.now());
                    Set<String> serviceSet;
                    try
                    {
                        serviceSet = !string.isBlank(serviceString)? 
                        (Set<String>)JSON.deserialize(serviceString,Set<String>.class) :
                        new Set<String>();    
                    }
                    catch(Exception e)
                    {

                    }
                    // system.debug('serviceString: ' + serviceString);
                    // system.debug('serviceSet: ' + serviceSet);
                    if(serviceSet != null && serviceSet.size() > 0)
                    {

                        for(String serviceName : serviceSet)
                        {
                            serviceProducts.add(new SC_Select_Options(serviceName,serviceName));
                        }
                        createWrapper.policyDomains = new SC_Select_Options_Wrapper(serviceProducts,null);
                    }
                }
                system.debug('Start Time: Contracts' + Datetime.now());
                for (Merge_Contract_Detail__c detail : SC_Jarvis_utility.getContractDetails(contracts,null,new Set<String> {accountId},0))
                {
                    marketingProducts.add(detail.Product_Id__c);
                }
                system.debug('End Time: Contracts' + Datetime.now());
                system.debug('Start Time: mapping' + Datetime.now());
                for(Siebel_Marketing_Prod_Case_Prod_Map__c mappingRec: SC_Jarvis_utility.getMappingRecords(null,marketingProducts))
                {
                    caseProducts.add(mappingRec.Case_Product_Name__c);
                }
                system.debug('End Time: mapping' + Datetime.now());
            }
            else
            {
                accountId = null;
            }
            system.debug('Start Time: LOVs' + Datetime.now());
            for(Case_Product_Siebel_LOV__c siebelLOV: SC_Jarvis_utility.getLOVs(SC_Jarvis_utility.getAreas(category),accountId,caseProducts))
            {
                if(!uniqueFilter.contains(siebelLOV.Product__c))
                {
                    uniqueFilter.add(siebelLOV.Product__c);
                    productSelectors.add(new SC_Select_Options(siebelLOV.Product__c,siebelLOV.Product__c));
                }
                emergingProduct = siebelLOV.Area__c == 'Emerging Products Eng'? true: emergingProduct;
                carrierProduct = siebelLOV.Area__c == 'Carrier Products'?true:carrierProduct;
            }
            system.debug('End Time: LOVs' + Datetime.now());
        }
        
        createWrapper.products = new SC_Select_Options_Wrapper(productSelectors,null);

        List<SC_Select_Options> severitySelectors = new List<SC_Select_Options>();
        String defaultSeverity;

        String carrierEmerging = carrierProduct? 'Carrier' : (emergingProduct? 'Emerging' : '');
        // Changes for ESESP-7013
        accountId =accountId == null? param.get('accountId') : accountId;
        //End of changes for ESESP-7013
        for (String severityValue : SC_Jarvis_utility.getSeverityValuesCreateCase(accountId,category,carrierEmerging))
        {
            system.debug('severityValue: ' + severityValue);
            defaultSeverity = defaultSeverity == null?severityValue:defaultSeverity;
            severitySelectors.add(new SC_Select_Options(severityValue,severityValue));
        }
        createWrapper.severity = new SC_Select_Options_Wrapper(severitySelectors, defaultSeverity);

        return createWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static CaseCreateWrapper getProblem(String paramMap)
    {
        Map<String,String> param = (Map<String,String>) JSON.deserialize(paramMap,Map<String,String>.class);
        CaseCreateWrapper createWrapper = new CaseCreateWrapper();
        List<SC_Select_Options> problemSelectors = new List<SC_Select_Options>();
        Set<String> uniqueFilter = new Set<String>();
        if(param.containsKey('accountId') && param.containsKey('product') && param.containsKey('category'))
        {
            string category = param.get('category');
            string subjectString = param.get('subject');
            Set<String> categoryFilter = SC_Jarvis_utility.getAreas(category);
            String accountId =category == 'AMG' || category == 'Billing' ? null : param.get('accountId');
            Set<String> products = new Set<String>{param.get('product')};
            Boolean emergingProduct = false;
            Boolean carrierProduct = false;
            Boolean hasOther= false;
            system.debug('Start Time: LOVs' + Datetime.now());
            for(Case_Product_Siebel_LOV__c siebelLOV: SC_Jarvis_utility.getLOVs(categoryFilter,accountId,products))
            {
                emergingProduct = category == 'Technical' && siebelLOV.Area__c == 'Emerging Products Eng'? true: emergingProduct;
                carrierProduct = category == 'Technical' && siebelLOV.Area__c == 'Carrier Products'?true:carrierProduct;
                if(siebelLOV.Problem__c == 'Other')
                {
                    hasOther = true;
                }
                else if(!uniqueFilter.contains(siebelLOV.Problem__c))
                {
                    uniqueFilter.add(siebelLOV.Problem__c);
                    problemSelectors.add(new SC_Select_Options(siebelLOV.Problem__c,siebelLOV.Problem__c));    
                }                
            }
            system.debug('End Time: LOVs' + Datetime.now());
            if(hasOther)
            {
                problemSelectors.add(new SC_Select_Options('Other','Other'));    
            }
            String defaultValue = carrierProduct? 'Carrier' : (emergingProduct? 'Emerging' : null);
            createWrapper.products = new SC_Select_Options_Wrapper(problemSelectors,defaultValue);
            
    
            List<SC_Select_Options> severitySelectors = new List<SC_Select_Options>();
            String defaultSeverity;
            //Changes for ESESP-7013
            accountId =accountId == null? param.get('accountId') : accountId;
            //End of changes for ESESP-7013
            for (String severityValue : SC_Jarvis_utility.getSeverityValuesCreateCase(accountId,category,defaultValue))
            {
                defaultSeverity = defaultSeverity == null?severityValue:defaultSeverity;
                severitySelectors.add(new SC_Select_Options(severityValue,severityValue));
            }
            createWrapper.severity = new SC_Select_Options_Wrapper(severitySelectors, defaultSeverity);

            //createWrapper.searchResults = getKnowledgeDiscussion(subjectString, param.get('product'));    
        }
        return createWrapper;
    }
	
    @AuraEnabled(cacheable=true) 
    public static CaseCreateWrapper getQuestionRecords(String product, String problem)
    {
        CaseCreateWrapper createWrapper = new CaseCreateWrapper();
        List<SC_Select_Options> options;
        List<QuestionWrapper> questionWrappers = new List<QuestionWrapper>();
        QuestionWrapper questionWrapper;
        String questionRecord;
        for(Case_Questionnaire__c questionRec : SC_Jarvis_utility.getQuestions(new Set<String> {product},new Set<String> {problem}))
        {
            questionRecord = !String.isBlank(questionRec.Question__c)?questionRec.Question__c.stripHtmlTags() :questionRec.Question__c ;
            questionWrapper = new QuestionWrapper(questionRec.Id,questionRecord,questionRec.Question_Type__c
            ,questionRec.Help_Text__c,questionRec.Required__c);
            if(questionRec.Question_Type__c == 'Picklist' && questionRec.Answer_Options__c != null)            
            {
                questionWrapper.options = new List<SC_Select_Options>();
                for(String optionValue : questionRec.Answer_Options__c.split('[\\n;,]+') )
                {
                    questionWrapper.options.add(new SC_Select_Options(optionValue,optionValue));
                }
            }
            questionWrappers.add(questionWrapper);
        }

        if(questionWrappers.size() > 0)
        {
            createWrapper.questions = questionWrappers;
        }
        return createWrapper;
    }

    @AuraEnabled 
    public static String createCase(String caseRecord, String filesToAttach)
    {
        //system.debug('caseRecord: ' + caseRecord);
        Map<String,String> caseFields = (Map<String,String>)JSON.deserialize(caseRecord, Map<String,String>.class);
        List<Id> fileContentDocumentIds = (List<Id>)JSON.deserialize(filesToAttach, List<Id>.class);
        
        Case caseRecordToInsert = new Case();
        String caseProduct;
        String recordType = caseFields.get('RecordType');
        
        caseProduct = caseFields.containsKey('Case_Product__c')? caseFields.get('Case_Product__c'):'';
        Integer severityInteger;
        for(string caseField : caseFields.keySet())
        {
            if(caseField != 'Case_Product__c' && caseField != 'RecordType')
            {
                caseRecordToInsert.put(caseField,caseFields.get(caseField));    
            }
        }
        caseRecordToInsert.contactId = contactId;
        severityInteger = caseRecordToInsert.Severity__c != null && 
        caseRecordToInsert.Severity__c.contains('1') ? 1 : 
        caseRecordToInsert.Severity__c.contains('2')? 2:
        caseRecordToInsert.Severity__c.contains('3')? 3:
        caseRecordToInsert.Severity__c.contains('4')? 4 : 3;
        system.debug('caseRecordToInsert.Severity__c: ' + caseRecordToInsert.Severity__c);
        system.debug('severityInteger: ' + severityInteger);
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        caseRecordToInsert.recordTypeId = recordTypeId;
        
        if(caseProduct != '')
        {
            List<EB_AccountProductMap__c> caseProductRecList = SC_Jarvis_utility.getCaseProduct(caseProduct,caseRecordToInsert.AccountId);
            if(caseProductRecList.size() >0)
            {
                caseRecordToInsert.Case_Product__c = caseProductRecList.get(0).Id;
            }
    
        }
        if(recordType == 'Professional Services')
        {
            caseRecordToInsert.Service_Contract_Id__c ='';
            Set<String> uniqueServiceContracts = new Set<String>();

            String serviceString;
            Map<String,Map<String,String>> accountToContract;
            try
            {
                serviceString = SC_Jarvis_utility.getServicesPS(new Set<String>{caseRecordToInsert.AccountId},null,new Set<String>{caseRecordToInsert.Service__c},0);
                accountToContract = !String.isBlank(serviceString)? 
                (Map<String,Map<String,String>>)JSON.deserialize(serviceString,Map<String,Map<String,String>>.class):
                null ;
            }
            catch(Exception e)
            {

            }
            if(accountToContract != null && accountToContract.size() > 0 && 
            accountToContract.get(caseRecordToInsert.AccountId) != null && 
            accountToContract.get(caseRecordToInsert.AccountId).containsKey(caseRecordToInsert.Service__c)) 
            {
                caseRecordToInsert.Service_Contract_Id__c = accountToContract.get(caseRecordToInsert.AccountId).get(caseRecordToInsert.Service__c);
            }
            caseRecordToInsert.Severity__c = String.ValueOf(severityInteger);
        }
        else if(recordType == 'AMG' || recordType == 'Billing')
        {
            caseRecordToInsert.Community_Sharing_Set_Account_Lookup__c = caseRecordToInsert.AccountId;
            severityInteger = severityInteger == 4? 3: severityInteger;
            caseRecordToInsert.Severity__c = String.ValueOf(severityInteger);
        }
        else if(recordType == 'Managed Security')
        {
            //List<Authorized_Contact__c> authContacts= SC_Jarvis_utility.getAuthorizedContact(contactId, 1,new List<String>{caseRecordToInsert.AccountId},new List<String>{caseRecordToInsert.Policy_Domain__c});
            //caseRecordToInsert.Can_Instruct__c = authContacts != null && authContacts.size() == 1? authContacts.get(0).Instruct__c : false;
            caseRecordToInsert.Severity__c = String.ValueOf(severityInteger);
        }
        else if(recordType == 'Technical')
        {
            severityInteger = severityInteger == 4? 3: severityInteger;
            caseRecordToInsert.Severity__c = String.ValueOf(severityInteger);
            if(
                SC_RiverbedCaseProdID__c.getValues('Riverbed_SAAS_OEM').Case_Product_ID__c != null
                &&
                caseRecordToInsert.Case_Product__c != null
                &&
                (SC_RiverbedCaseProdID__c.getValues('Riverbed_SAAS_OEM').Case_Product_ID__c).contains(caseRecordToInsert.Case_Product__c)
            )
            {

                caseRecordToInsert.ProductPL__c = caseProduct;
                caseRecordToInsert.Sub_Area_EPE__c = caseRecordToInsert.Problem__c;
                caseRecordToInsert.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Emerging Products Engineering').getRecordTypeId();                
            }
            
        }
        else if(recordType == 'Emerging Products Engineering')
        {
            caseRecordToInsert.ProductPL__c = caseRecordToInsert.Case_Product__c!= null? caseProduct : null;
            caseRecordToInsert.Sub_Area_EPE__c = caseRecordToInsert.Problem__c;
            caseRecordToInsert.Severity__c = String.ValueOf(severityInteger);
        }
        caseRecordToInsert.Created_By_Account__c = contactAccountId; 
        
        String returnString;
        try 
        {
            caseRecordToInsert.Validation_Override__c = true;
            //caseRecordToInsert.Case_Assignment_Using_Active_Rules__c = true;
            caseRecordToInsert.Do_Not_Show_in_Portal__c = false;
            caseRecordToInsert.AKAM_Case_ID__c = null;
            //system.debug('caseRecordToInsert: ' + caseRecordToInsert);
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            
            caseRecordToInsert.setOptions(dmo); 
    
            insert caseRecordToInsert;
            returnString = caseRecordToInsert.Id;
            if(fileContentDocumentIds.size() > 0) {
                List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
                for(String cdlId : fileContentDocumentIds) {
                    newLinks.add(new ContentDocumentLink(ContentDocumentId=cdlId, LinkedEntityId=returnString));
                }
                insert newLinks;
            }
        } 
        catch (Exception e) 
        {
            returnString = e.getMessage();
            SC_Jarvis_utility.sendErrorMails('Jarvis Case Create Error','Exception: ' , e.getMessage());
        }
        return returnString;

    }

    @AuraEnabled(cacheable=true) 
    public static CaseDetailWrapper getCaseRecord(String caseRecordId)
    {   
        CaseDetailWrapper wrapper;
        if(hasCurrentRecordAccess == null)
        {
            hasCurrentRecordAccess = getCaseContactAccess(caseRecordId,true) != 'None' ? true : false;
        }
        if(!hasCurrentRecordAccess)
        {
            return wrapper;
        }

        SC_Jarvis_utility.setSeverityMap();

        List<Case> caseRec = [Select AccountId, Severity__c, RecordType.Name,Policy_Domain__r.Name,Case_Product__r.Name, Parent_Account__r.Name, Parent_Account__c,
        Owner.Name,OwnerId,Service__c,Request_Type__c,Customer_Problem__c,Problem__c,Sub_Type__c,Contact.Name, Parent_Account__r.Akam_Account_Id__c, 
        Contact.Email, Contact.Phone, Contact.Company__c,Status, Created_By_Account__c,Created_By_Account__r.Name, CreatedDate from Case where Id = :caseRecordId];
        
        Case caseRecord; 
        if(caseRec.size() != 1)
        {
            return wrapper;
        }
        
        caseRecord = caseRec.get(0);


        Set<String> contractIds = new Set<String>();
        for(Jarvis_Contact_ACC_Permission_Contract__c permissionRec: [Select Contract__c from 
        Jarvis_Contact_ACC_Permission_Contract__c 
        where Active__c = true and Active_Contract__c = true and 
        Customer_Permission__r.Contact__c = :contactId and Permission__c != null])
        {
            contractIds.add(permissionRec.Contract__c);
        }        
        
        //ESESP-6568: Start of changes
        Boolean editAccess = caseRecord.RecordType.Name != 'Partner Technical Support'? 
        SC_Jarvis_utility.getUserEditAccess(userId,caseRecordId) : false;

        String recordType = caseRecord.RecordType.Name != 'Partner Technical Support'?
        caseRecord.RecordType.Name : SC_Jarvis_utility.getAkamaiRecordType(caseRecord.RecordType.Name,caseRecord.Sub_Type__c);

        String subType = caseRecord.RecordType.Name != 'Partner Technical Support'?
        caseRecord.Sub_Type__c : '';

        wrapper = new CaseDetailWrapper (caseRecord,editAccess,
        SC_Jarvis_utility.getSeverityValuesCorrespondingToCase(recordType,subType,
        caseRecord.AccountId,caseRecord.Severity__c),SC_Jarvis_utility.getStatusValue(caseRecord.Status),caseRecord.CreatedDate.format(),recordType,subType);
        ////ESESP-6568: End of changes

        if(SC_Jarvis_utility.getChildContracts(contractIds,1).size() == 1 &&
        contactAccountId == caseRecord.AccountId)
        {
            wrapper.isReseller = true;
        }

        return wrapper;
    }

    @AuraEnabled 
    public static CaseCreateWrapper cloneSetup(String caseRecordId)
    {   
        if(!checkForCloneAccess(caseRecordId))
        {
            return null;
        }
        List<Case> caseRecs;
        if(caseRecordForClone == null )
        {
            caseRecs = [Select AccountId,Sub_Type__c,Account.Name,account.akam_account_id__c,RecordTypeId,RecordType.Name,
            Policy_Domain__r.Name,Policy_Domain__c,Case_Product__r.Name, Parent_Account__c, Parent_Account__r.Name, Parent_Account__r.Akam_Account_Id__c,
            Case_Product__c,Service__c,Request_Type__c,Customer_Problem__c,Problem__c, Subject from Case where Id = :caseRecordId];
        }
        else
        {
            caseRecs = new List<Case>();
            caseRecs.add(caseRecordForClone);
        }
        CaseCreateWrapper wrapper = new CaseCreateWrapper();
        List<SC_Select_Options> selectionOps = new List<SC_Select_Options>();
        String caseProduct;
        case caserecord;
        if(caseRecs.size() == 1)
        {
            caserecord = caseRecs.get(0);
            wrapper.accounts = new List<Account>();
            wrapper.accounts.add(new Account(Id = caserecord.AccountId, 
            Akam_Account_ID__c = caserecord.account.akam_account_id__c, Name = caserecord.Account.Name));

            switch on caserecord.RecordType.Name 
            {
                when 'AMG' 
                {
                    if(caserecord.Parent_Account__c != null){
                        wrapper.parentAccounts = new Set<Account>();
                        wrapper.parentAccounts.add(new Account(Id = caserecord.Parent_Account__c, 
            				Akam_Account_ID__c = caserecord.Parent_Account__r.Akam_Account_Id__c, Name = caserecord.Parent_Account__r.Name));
                        
                    }
                    selectionOps.add(new SC_Select_Options('Client Services Manager/ Business Support Issue','AMG'));
                    wrapper.categories = new SC_Select_Options_Wrapper(selectionOps, 'AMG');
                    selectionOps.clear();

                    selectionOps.add(new SC_Select_Options(caserecord.Service__c,caserecord.Service__c));
                    wrapper.products = new SC_Select_Options_Wrapper(selectionOps, caserecord.Service__c);
                    selectionOps.clear();

                    selectionOps.add(new SC_Select_Options(caserecord.Request_Type__c,caserecord.Request_Type__c));
                    wrapper.problems = new SC_Select_Options_Wrapper(selectionOps, caserecord.Request_Type__c);
                    selectionOps.clear();    

                    caseProduct = caserecord.Service__c;
                }	
                when 'Billing' 
                {	
                    if(caserecord.Parent_Account__c != null){
                        wrapper.parentAccounts = new Set<Account>();
                        wrapper.parentAccounts.add(new Account(Id = caserecord.Parent_Account__c, 
            				Akam_Account_ID__c = caserecord.Parent_Account__r.Akam_Account_Id__c, Name = caserecord.Parent_Account__r.Name));
                        
                    }
                    selectionOps.add(new SC_Select_Options('Billing Support Issue or Question','Billing'));
                    wrapper.categories = new SC_Select_Options_Wrapper(selectionOps, 'Billing');
                    selectionOps.clear();
    
                    selectionOps.add(new SC_Select_Options(caserecord.Service__c,caserecord.Service__c));
                    wrapper.products = new SC_Select_Options_Wrapper(selectionOps, caserecord.Service__c);
                    selectionOps.clear();

                    selectionOps.add(new SC_Select_Options(caserecord.Request_Type__c,caserecord.Request_Type__c));
                    wrapper.problems = new SC_Select_Options_Wrapper(selectionOps, caserecord.Request_Type__c);
                    selectionOps.clear();    
                    
                    caseProduct = caserecord.Service__c;
                }
                when 'Technical' 
                {		
                    selectionOps.add(new SC_Select_Options('Technical Support Issue','Technical'));
                    wrapper.categories = new SC_Select_Options_Wrapper(selectionOps, 'Technical');
                    selectionOps.clear();
    
                    selectionOps.add(new SC_Select_Options(caserecord.Case_Product__r.Name,caserecord.Case_Product__r.Name));
                    wrapper.products = new SC_Select_Options_Wrapper(selectionOps, caserecord.Case_Product__r.Name);
                    selectionOps.clear();

                    selectionOps.add(new SC_Select_Options(caserecord.Customer_Problem__c,caserecord.Customer_Problem__c));
                    wrapper.problems = new SC_Select_Options_Wrapper(selectionOps, caserecord.Customer_Problem__c);
                    selectionOps.clear();    

                    caseProduct = caserecord.Case_Product__r.Name;

                }
                when 'Managed Security' 
                {		
                    selectionOps.add(new SC_Select_Options('Managed Security Support','SOCC'));  
                    wrapper.categories = new SC_Select_Options_Wrapper(selectionOps, 'SOCC');
                    selectionOps.clear();
    
                    selectionOps.add(new SC_Select_Options(caserecord.Policy_Domain__r.Name,caserecord.Policy_Domain__c));
                    wrapper.policyDomains = new SC_Select_Options_Wrapper(selectionOps, caserecord.Policy_Domain__c);

                    selectionOps.clear();

                    selectionOps.add(new SC_Select_Options(caserecord.Case_Product__r.Name,caserecord.Case_Product__r.Name));
                    wrapper.products = new SC_Select_Options_Wrapper(selectionOps, caserecord.Case_Product__r.Name);
                    selectionOps.clear();

                    selectionOps.add(new SC_Select_Options(caserecord.Problem__c,caserecord.Problem__c));
                    wrapper.problems = new SC_Select_Options_Wrapper(selectionOps, caserecord.Problem__c);
                    selectionOps.clear();    
                    caseProduct = caserecord.Case_Product__r.Name;
                }
                when 'Professional Services' 
                {		
                    selectionOps.add(new SC_Select_Options('Professional Services Request (billable)','PS'));
                    wrapper.categories = new SC_Select_Options_Wrapper(selectionOps, 'PS');
                    selectionOps.clear();    

                    selectionOps.add(new SC_Select_Options(caserecord.Case_Product__r.Name,caserecord.Case_Product__r.Name));
                    wrapper.products = new SC_Select_Options_Wrapper(selectionOps, caserecord.Case_Product__r.Name);
                    selectionOps.clear();

                    selectionOps.add(new SC_Select_Options(caserecord.Service__c,caserecord.Service__c));
                    wrapper.problems = new SC_Select_Options_Wrapper(selectionOps, caserecord.Service__c);
                    selectionOps.clear();    
    
                    caseProduct = caserecord.Case_Product__r.Name;
                }

            }  
            wrapper.searchResults = getKnowledgeDiscussion(caserecord.Subject, caseProduct);    
            String defaultSeverity;

            String carrierEmerging = caserecord.Sub_Type__c == 'Carrier'? 'Carrier' : 
                                        caserecord.RecordType.Name == 'Emerging Products Engineering'? 
                                            'Emerging' : '';
                
            for (String severityValue : SC_Jarvis_utility.getSeverityValuesCreateCase(caserecord.AccountId,wrapper.categories.defaultValue,carrierEmerging))
            {
                defaultSeverity = defaultSeverity == null?severityValue:defaultSeverity;
                selectionOps.add(new SC_Select_Options(severityValue,severityValue));
            }
            wrapper.severity = new SC_Select_Options_Wrapper(selectionOps, defaultSeverity);
            wrapper.loggedInContact = contactId;
            selectionOps.clear();
        }
        return wrapper;
    }
    
    // @AuraEnabled 
    public static Boolean checkForCloneAccess(String caseRecordId)
    {
        List<Case> caseRecs = [Select AccountId,Sub_Type__c,Account.Name,account.akam_account_id__c,RecordTypeId,RecordType.Name,
        Policy_Domain__r.Name,Policy_Domain__c,Case_Product__r.Name, Parent_Account__c, Parent_Account__r.Name, Parent_Account__r.Akam_Account_Id__c,
        Case_Product__c,Service__c,Request_Type__c,Customer_Problem__c,Problem__c, Subject from Case where Id = :caseRecordId];
        CaseCreateWrapper wrapper;
        Map<String,String> param = new Map<String,String>();
        Set<String> permissions = new Set<String>();
        Set<String> contracts = new Set<String>();

        if(caseRecs.size() != 1)
        {
            return false;
        }
        case caseRec = caseRecs.get(0);
        caseRecordForClone = caseRec;

        //wrapper = getCategories(caseRec.accountId);
        //if(wrapper.categories != null && wrapper.categories.options != null && wrapper.categories.options)        
        switch on caseRec.RecordType.Name 
        {
            when 'AMG' 
            {
                List<Jarvis_Contact_ACC_Permission_Contract__c> permissionList = new List<Jarvis_Contact_ACC_Permission_Contract__c>();
                permissionList = SC_Jarvis_utility.getPermissionRecords(contactId,caseRec.accountId,SC_Jarvis_utility.getAccessSet('Write'),0);
                
                if(permissionList.size() > 0)
                {
                    if(caseRec.Parent_Account__c == null){
                        return true;
                    }
                    else{
                        return SC_Jarvis_utility.parentAccountCheckForClone(caseRec.Parent_Account__c, permissionList);
                    }
                }            
            }	
            when 'Billing' 
            {		
                List<Jarvis_Contact_ACC_Permission_Contract__c> permissionList = new List<Jarvis_Contact_ACC_Permission_Contract__c>();
                permissionList = SC_Jarvis_utility.getPermissionRecords(contactId,caseRec.accountId,SC_Jarvis_utility.getAccessSet('Write'),0);
                
                if(permissionList.size() > 0)
                {
                    if(caseRec.Parent_Account__c == null){
                        return true;
                    }
                    else{
                        return SC_Jarvis_utility.parentAccountCheckForClone(caseRec.Parent_Account__c, permissionList);
                    }
                }               
            }
            when 'Technical' 
            {		
                permissions.add(technicalAccessString);
                for (Jarvis_Contact_ACC_Permission_Contract__c contractPermission : SC_Jarvis_utility.getPermissionRecords(contactId,caseRec.AccountId,permissions,0))
                {
                    contracts.add(contractPermission.Contract__c);
                }
                if(contracts.size() > 0 && caseRec.Case_Product__r.Name != null)
                {
                    Set<String> marketingProducts = new Set<String>();
                
                    for(Siebel_Marketing_Prod_Case_Prod_Map__c mappingRec: SC_Jarvis_utility.getMappingRecords(new Set<String>{caseRec.Case_Product__r.Name},null))
                    {
                        marketingProducts.add(mappingRec.Marketing_Product_ID__c);
                    }
                    
                    if(marketingProducts.size() > 0 && SC_Jarvis_utility.getContractDetails(contracts,marketingProducts,new Set<String> {caseRec.AccountId},1).size() == 1)
                    {
                        return true;
                    }
    
                }
                else if(contracts.size() > 0)
                {
                    return true;
                }
            }
            when 'Emerging Products Engineering'
            {
                permissions.add(technicalAccessString);
                for (Jarvis_Contact_ACC_Permission_Contract__c contractPermission : SC_Jarvis_utility.getPermissionRecords(contactId,caseRec.AccountId,permissions,0))
                {
                    contracts.add(contractPermission.Contract__c);
                }
                if(contracts.size() > 0 && caseRec.Case_Product__r.Name != null)
                {
                    Set<String> marketingProducts = new Set<String>();
                
                    for(Siebel_Marketing_Prod_Case_Prod_Map__c mappingRec: SC_Jarvis_utility.getMappingRecords(new Set<String>{caseRec.Case_Product__r.Name},null))
                    {
                        marketingProducts.add(mappingRec.Marketing_Product_ID__c);
                    }
                    
                    if(marketingProducts.size() > 0 && SC_Jarvis_utility.getContractDetails(contracts,marketingProducts,new Set<String> {caseRec.AccountId},1).size() == 1)
                    {
                        return true;
                    }
    
                }
                else if(contracts.size() > 0)
                {
                    return true;
                }

            }
            when 'Managed Security' 
            {		
                if(SC_Jarvis_utility.getAuthorizedContact(contactId,1,null,new List<String>{caseRec.Policy_Domain__c}).size() == 1)
                {
                    return true;
                }
            }
            when 'Professional Services' 
            {		

                permissions.add(psAccessString);
                Set<String>serviceContractIds = new Set<String>();
                for (Jarvis_Contact_ACC_Permission_Contract__c contractPermission : SC_Jarvis_utility.getPermissionRecords(contactId,caseRec.AccountId,permissions,0))
                {
                    contracts.add(contractPermission.Contract__c);
                    serviceContractIds.add(contractPermission.Contract__r.Original_Contract_Id__c);
                }
                if(contracts.size() > 0 && caseRec.Case_Product__r.Name != null)
                {
                    Set<String> marketingProducts = new Set<String>();
                
                    for(Siebel_Marketing_Prod_Case_Prod_Map__c mappingRec: SC_Jarvis_utility.getMappingRecords(new Set<String>{caseRec.Case_Product__r.Name},null))
                    {
                        marketingProducts.add(mappingRec.Marketing_Product_ID__c);
                    }
                    
                    String serviceString = SC_Jarvis_utility.getServicesPS(null,serviceContractIds,new Set<String>{caseRec.Service__c},1);
                    Set<String>productNames;
                    try
                    {
                        productNames = !String.isBlank(serviceString) ? 
                        (Set<String>)JSON.deserialize(serviceString,Set<String>.class) :
                        null;
                    }
                    catch(Exception e)
                    {

                    }
    
                    if(
                        marketingProducts != null 
                        && 
                        marketingProducts.size() > 0 
                        &&    
                        SC_Jarvis_utility.getContractDetails(contracts,marketingProducts,new Set<String> {caseRec.AccountId},1).size() == 1
                        &&
                        productNames != null 
                        &&
                        productNames.size() == 1
                    )                    
                    {
                        return true;
                    }
    
                }
                else if(contracts.size() > 0)
                {
                    return true;
                }
            }

        }  
        return false;
    }

    public class MainCasePathWrapper
    {
        @AuraEnabled public string akamcaseid; 
        @AuraEnabled public string subject;         
        @AuraEnabled public string status;
        @AuraEnabled public string description;
        @AuraEnabled public map<string,string> statusHelptextMap;
        @AuraEnabled public list<subLabelValueWrapper> caseValues;
        @AuraEnabled public list<subLabelValueWrapper> lstofpathvalues;
        @AuraEnabled public map<string,list<subLabelValueWrapper>> statusCaseValuesMap;
        @AuraEnabled public Boolean editAccess; 
        @AuraEnabled public Boolean cloneAccess; 
    }
    
    public class SubLabelValueWrapper
    {
        @AuraEnabled public string label;
        @AuraEnabled public string value;
    }
    
        
    @Auraenabled(cacheable=true)
    //ESESP-6568: changes in function to disable required access
    public static MainCasePathWrapper getLabelDetails(map<string, string> labelvalues, string caseid, string recordTypeName, Boolean preview, string subType)
    {
        mainCasePathWrapper submainCasePathWrapper = new mainCasePathWrapper();
        if(hasCurrentRecordAccess == null)
        {
            hasCurrentRecordAccess = getCaseContactAccess(caseid,true) != 'None' ? true : false;
        }
        if(!hasCurrentRecordAccess)
        {
            return submainCasePathWrapper;
        }
        //ESESP-6568: Start of changes
        string rec;
        if(recordTypeName == 'Partner Technical Support')
        {
            rec = SC_Jarvis_utility.getAkamaiRecordType('Partner Technical Support',subType);
        } else if(recordTypeName == 'Emerging Products Engineering'){
            rec = 'Technical';
        } else {
            rec = recordTypeName;
        }
        //ESESP-6568: End of changes

        rec += !preview? '-%' : '-HighlightPanel';

        Set<String> statusToSkip = new Set<String>();
        List<String> statusValues = new List<String>();   
        Set<String> caseFieldsToQuery = new Set<String>();
        String metadataQuery = 'select MasterLabel,Value__c, Case_Field_API__c from SC_CommunityUtility__mdt where';
        metadataQuery += ' MasterLabel like :rec';

        list<SC_CommunityUtility__mdt> pathdetails = database.query(metadataQuery);
        for(SC_CommunityUtility__mdt metadataRec: pathdetails)
        {
            if(metadataRec.MasterLabel.contains('Status'))
            {
                statusValues.addAll(metadataRec.Value__c.split(','));
            }
            else
            {
                caseFieldsToQuery.addAll(metadataRec.Case_Field_API__c.split(','));
            }
        }
        caseFieldsToQuery.add('Id');
        caseFieldsToQuery.add('OwnerId');
        caseFieldsToQuery.add('AKAM_Case_ID__c');
        caseFieldsToQuery.add('Subject');
        caseFieldsToQuery.add('Next_Action__c');
        caseFieldsToQuery.add('Status');
        caseFieldsToQuery.add('Description');
        caseFieldsToQuery.add('AccountId');
        caseFieldsToQuery.add('Severity__c');
        caseFieldsToQuery.add('RecordType.Name');
        caseFieldsToQuery.add('Sub_Type__c');
        //ESESP-6070 - added field for query
        caseFieldsToQuery.add('AKAM_Closed_Date__c');
        // for(String statusValue: statusToSkip)
        // {
        //     Integer index = statusValues.indexOf(statusValue);
        //     if(index != -1)
        //     {
        //         statusValues.remove(index);
        //     }
        // }

        String caseQuery = 'Select ' + String.join((Iterable<String>)caseFieldsToQuery, ',') + ' from Case where Id = :caseid';
        system.debug('caseQuery: ' + caseQuery);
        List<Case> caseRecords = Database.query(caseQuery);

        //List<String> statusValues = new List<String>();   
        
        
        List<subLabelValueWrapper> subLabelValueWrapperList=new list<subLabelValueWrapper>();
        subLabelValueWrapper EachsubLabelValueWrapper;        
        
        //case lstcase = [select account.name,akam_case_id__c,subject,status,recordtype.name,Case_Owner_Name__c,
        // Next_Action__c,AKAM_Closed_Date__c,Service__c,Age_days__c,Case_Prod_Name__c, 
        // Time_to_Initial_Response_TTIR__c,Resolved_Date__c ,Solution_Summary__c ,
        // CreatedDate,severity__c,ownerId from case where id = :caseid];

        Case lstcase = caseRecords.get(0);

        //submainCasePathWrapper.Status=statusToSkip.contains(lstcase.status) ? 'Work in Progress' : lstcase.status;
        submainCasePathWrapper.akamcaseid=lstcase.AKAM_Case_ID__c;
        submainCasePathWrapper.subject=lstcase.Subject;
        submainCasePathWrapper.status = SC_Jarvis_utility.getStatusValue(lstcase.Status);
        submainCasePathWrapper.description = lstcase.Description;
        //statusValues=recordtypeStatusValues.get(lstcase.recordtype.name);        
        
        map <string,string> statusHelptextMap = new map<string,string>();
        //string rec = lstcase.recordtype.name+'-%';
        
        //list<SC_CommunityUtility__mdt> pathdetails = [select MasterLabel,Value__c, Case_Field_API__c from SC_CommunityUtility__mdt where MasterLabel like :rec];
        
        for(string eachstring : statusValues)
        {
            EachsubLabelValueWrapper = new subLabelValueWrapper();
            String currentStatus = SC_Jarvis_utility.getStatusValue(eachstring);
            if(!statusToSkip.contains(currentStatus))
            {
                statusToSkip.add(currentStatus);
                string apiname = currentStatus.replaceall(' / ','_').replaceall(' ','_');
                EachsubLabelValueWrapper.label=labelvalues.get(apiname);
                EachsubLabelValueWrapper.value=currentStatus;
                
                subLabelValueWrapperList.add(EachsubLabelValueWrapper);
                
                if(currentStatus=='In Progress')
                {
                    apiname+=lstcase.Next_Action__c=='Customer'?'Customer':'NotCustomer';
                }
                statusHelptextMap.put(currentStatus,labelvalues.get(apiname+'_Helptext'));
    
            }
    
        }
        submainCasePathWrapper.lstofpathvalues=subLabelValueWrapperList;
        
        List<subLabelValueWrapper> subStatusLabelValueWrapperList=new list<subLabelValueWrapper>();
        List<subLabelValueWrapper> caseValues=new list<subLabelValueWrapper>();

        map<string,list<subLabelValueWrapper>> statusCaseValuesMap = new map<string,list<subLabelValueWrapper>>();
        
        for(SC_CommunityUtility__mdt eachrec : pathdetails)
        {
            if(!eachrec.masterlabel.contains('Status'))
            {
                list<string> casefields = eachrec.Value__c.split(',');
                list<string> caseapis = eachrec.Case_Field_API__c.split(',');
    
                for(integer i=0;i<casefields.size();i++)
                {	
                    EachsubLabelValueWrapper = new subLabelValueWrapper();
                    string caselabel = 'CaseLabel_'+casefields[i].replaceall(' ','_');
                    EachsubLabelValueWrapper.label=labelvalues.get(caselabel);
                    string currentVal;
                    if(caseapis[i].contains('.'))
                    {
                        String relatedFieldObject = (caseapis[i]).split('\\.')[0];
                        String relatedFieldName = (caseapis[i]).split('\\.')[1];
                        currentVal = string.valueof(lstcase.getsObject(relatedFieldObject).get(relatedFieldName));
                    }
                    else
                    {
                        currentVal = string.valueof(lstcase.get(caseapis[i]));
                    }
                    
                    if(caselabel.contains('Owner') && !String.valueOf(lstcase.OwnerId).startsWith('005'))
                    {
                        EachsubLabelValueWrapper.value = 'In Queue';
                    }
                    else if(caselabel.contains('Status'))                    
                    {
                        EachsubLabelValueWrapper.value = SC_Jarvis_utility.getStatusValue(currentVal);
                        
                    }
                    else if(caselabel.contains('Severity'))
                    {
                        EachsubLabelValueWrapper.value=	SC_Jarvis_utility.getSeverityValuesCorrespondingToCase(lstcase.RecordType.Name,lstcase.Sub_Type__c,
                        lstcase.AccountId,lstcase.Severity__c);
                    }
                    else
                    {
                        EachsubLabelValueWrapper.value=	caseapis[i].containsignorecase('Date') && 
                        lstcase.get(caseapis[i]) != null ? 
                        ((Datetime)lstcase.get(caseapis[i])).format() :  currentVal;
                    }
                    
                    if(eachrec.masterLabel.contains('HighlightPanel'))
                    {
                        caseValues.add(EachsubLabelValueWrapper);
                    }             
                    else
                    {
                        subStatusLabelValueWrapperList.add(EachsubLabelValueWrapper);
                    }
                    
                }
                if(!eachrec.masterLabel.contains('HighlightPanel'))
                {
                    string status = eachrec.MasterLabel.split('-')[1];
                    status = SC_Jarvis_utility.getStatusValue(status);
                    statusCaseValuesMap.put(status,subStatusLabelValueWrapperList);
                    subStatusLabelValueWrapperList= new list<subLabelValueWrapper>();
                }
    
            }

            
        }
        if(!preview)
        {
            submainCasePathWrapper.statusCaseValuesMap=statusCaseValuesMap;
            submainCasePathWrapper.statusHelptextMap=statusHelptextMap;
    
            //ESESP-6568: Set both access to false if RT is PTS
            //ESESP-6070: Start of changes
            submainCasePathWrapper.editAccess = !(lstcase.RecordType.Name == 'Partner Technical Support') && SC_Jarvis_utility.getUserEditAccess(UserInfo.getUserId(), caseid) && (lstcase.AKAM_Closed_Date__c != null ? SC_Jarvis_utility.getDaysSinceClosed(lstcase.AKAM_Closed_Date__c) <= 14 : true) ;
            //ESESP-6070: End of changes
            submainCasePathWrapper.cloneAccess = !(lstcase.RecordType.Name == 'Partner Technical Support') && checkForCloneAccess(caseid) ;
            //ESESP-6568: End of changes
    
        }
        submainCasePathWrapper.caseValues = caseValues;
        return submainCasePathWrapper;
        
    }
    
    
    @AuraEnabled
    public static Boolean mitigateCase(string caseId) 
    {
        Case cs = new Case();
        cs.id = caseId;
        cs.status = 'Mitigated / Solution Provided';
        cs.validation_override__c = true;
        cs.Solution_Summary__c = 'Customer Requested Closure via Web';
        cs.Resolved_Date__c = datetime.now();
        try 
        {
            update cs;
        } 
        catch (Exception e) 
        {
            SC_Jarvis_utility.sendErrorMails('Jarvis Mitigate Case Error','Exception: ' , e.getMessage());
        }
        SC_CommunityCommentController.insertnewComment((String)cs.Id, 'JARVIS', 'Case', 'Issue Mitigated', 'Public');   
        
        return true;
    }

    @AuraEnabled
    public static String alsoNotifyCheck(string emailString, String accountIdString, String parentAccountIdString, String caseRecord, String updateRecord, String filesToAttach) 
    {
        if(emailString != null && accountIdString != null)
        {
            List<String> emails = emailString.split('[,;\\s\\n]+');
            Set<String> emailsSet = new Set<String>();
            
            if(emails != null && emails.size() > 0)
            {
                for(String emailValue : emails)
                {
                    if(emailValue != null && !emailValue.contains('@akamai.com'))
                    {
                        emailsSet.add(emailValue.trim());    
                    }                    
                }
                for(AccountContactRelation acrRec : [Select contact.email from AccountContactRelation where
                accountid = :accountIdString and isactive = true and contact.email in :emails])
                {
                    emailsSet.remove(acrRec.contact.email);
                }
                if(emailsSet.size() > 0)
                {                    
                    return caseRecord != null || updateRecord != null? 
                    '<br />' + String.join((Iterable<String>)emailsSet, '<br />') + '<br />':
                    '';
                }
                else if(emailsSet.size() == 0 && caseRecord != null && (parentAccountIdString == null || parentAccountIdString == ''))
                {
                    return createCase(caseRecord, filesToAttach);
                }
                else if(emailsSet.size() == 0 && updateRecord != null)
                {
                    return updateCaseRecord(updateRecord);
                }
            }
        }
        if(parentAccountIdString == null || parentAccountIdString == '')
        	return 'Success';
        else
            return 'Success with Parent';
    }


    @AuraEnabled
    public static String updateCaseRecord(String updateRecord) 
    {
        Map<String,String> caseFields = (Map<String,String>)JSON.deserialize(updateRecord, Map<String,String>.class);
        Case caseRecordToInsert = new Case();

        for(string caseField : caseFields.keySet())
        {
            caseRecordToInsert.put(caseField,caseFields.get(caseField));            
        }
        caseRecordToInsert.Validation_Override__c = true;
        //ESESP-6277 - Added field to Update
        caseRecordToInsert.Last_Case_Update__c = Datetime.now();            

        try 
        {
            update caseRecordToInsert;        
        } 
        catch (Exception e) 
        {
            SC_Jarvis_utility.sendErrorMails('Jarvis Case Update Error','Exception: ' , e.getMessage());
        }        
        return caseRecordToInsert.Id;
    }

    @AuraEnabled
    public static Boolean getCanInstruct(String caseRecordId)  
    {
        List<Case> caseRecs = [Select Id, AccountId, Policy_Domain__c, contactId from Case where id = :caseRecordId 
        and Policy_Domain__c != null and AccountId != null and contactId != null];
        if(caseRecs != null && caseRecs.size() == 1)
        {
            Case caseRec= caseRecs.get(0);
            List<Authorized_Contact__c> authContacts= SC_Jarvis_utility.getAuthorizedContact(caseRec.contactId, 1,new List<String>{caseRec.AccountId},new List<String>{caseRec.Policy_Domain__c});
            return authContacts != null && authContacts.size() == 1? authContacts.get(0).Instruct__c : false;
        }
        return false;
    }
    
    @AuraEnabled
    public static String getCaseContactAccess(String recordId,Boolean currentUser)
    {
        String accessLevel='None';
        String userId;
        if(currentUser == null || !currentUser)
        {
            List<Case> caseRecs = [Select Id, contactId, contact.Akam_Contact_Id__c from Case where id = :recordId 
            and contactId != null];
            if(caseRecs != null && caseRecs.size() == 1)
            {
                Case caseRec = caseRecs.get(0);                
                List<User> users = [Select Id from User where akam_User_Id__c = :caseRec.contact.Akam_Contact_Id__c or
                contactId = :caseRec.contactId];
                if(users != null && users.size() > 0)
                {
                    userId = users.get(0).Id;
                }        
            }
        }
        else if(currentUser)
        {
            userId = UserInfo.getUserId();
        }
        if(userId != null)
        {
            List<UserRecordAccess> accessRecs = [SELECT RecordId , hasEditaccess, hasReadAccess FROM UserRecordAccess where RecordId  = :recordId 
            and userId = :userId];        
            if(accessRecs != null && accessRecs.size() == 1)
            {
                accessLevel = accessRecs.get(0).hasEditaccess? 'Edit' : 
                                accessRecs.get(0).hasReadAccess ? 'Read':
                                'None';
            }
    
        }

        return accessLevel;
    }

}