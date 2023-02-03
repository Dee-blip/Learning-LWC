/**
**/
public without sharing class l2qChimeCloneClass {
    @AuraEnabled
    public static List<productWrapper> getProductsForChime(String chimeId){
        try {
            List<Chime_Product_Association__c> listCPAs = [Select id,CHIME_Product__c,CHIME_Product__r.Product_Name__c from Chime_Product_Association__c where CHIME__c =:chimeId];
            List<productWrapper> wrapList = new List<productWrapper>();
            for(Chime_Product_Association__c cpa : listCPAs){
                productWrapper wrap = new productWrapper();
                wrap.productId = cpa.CHIME_Product__c;
                wrap.productName = cpa.CHIME_Product__r.Product_Name__c;
                wrapList.add(wrap);
            }
            return wrapList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class productWrapper{
        @AuraEnabled
        public Id productId{get;set;}
        @AuraEnabled
        public string productName{get;set;}
    }
    @AuraEnabled
    public static Id clonePOCToFullIntegrationForm(Id chimeId,Id oppId,String productList,string implementationType,boolean emergency,string chimeFormName, Boolean workatrisk){
        try{
            Chime__c chimeForm = [Select Id,Account__c,CHIME_Name__c,Business_Goals__c from chime__c where id=: chimeId];
            //Clone Chime Form
            Chime__c newChime = new Chime__c();      
            newChime.Stage__c ='Gating';
            newChime.Account__c=chimeForm.Account__c;
            newChime.CHIME_Name__c =chimeFormName;
            newChime.Opportunity__c = oppId;
            newChime.Implementation_Type__c = implementationType;
            newChime.Is_Emergency__c = emergency;
            newChime.Is_Work_At_Risk_Investment_Work__c = workatrisk;
            newChime.Business_Goals__c= chimeForm.Business_Goals__c;
            newChime.CHIME__c = chimeForm.Id;
            newChime.LOE_Review_Status__c = 'Review required';
			insert newChime;   
            System.debug('newChime'+newChime);
            
            //Clone CPAs
            List<String> prodList = (List<String>)Json.deserialize(productList, String[].class);
			//List<Chime_Product_Association__c > CPAs = [Select id,]
            List<Chime_Product_Association__c > CPAToBeCreated = new List<Chime_Product_Association__c >();
            Map<Id,Chime_Product_Template__c> mapProductTemplate = new Map<Id,Chime_Product_Template__c>();
            
            List<Chime_Product_Template__c> prodTemplateList = [Select id,Product__c,createddate from Chime_Product_Template__c where Product__c in:prodList order by createddate desc];
            
            //create map of product and template
            for(Chime_Product_Template__c template : prodTemplateList){
                if(!mapProductTemplate.containsKey(template.Product__c)){
                	mapProductTemplate.put(template.Product__c,template);
                }else{
                    if(template.CreatedDate > mapProductTemplate.get(template.Product__c).createddate){
                        mapProductTemplate.put(template.Product__c,template);
                    }
                }
            }
            
            
            for(String product :prodList){
                Id prodId = (Id)product;
                Chime_Product_Association__c cpa = new Chime_Product_Association__c();
                cpa.CHIME_Product__c =(Id)product;
                cpa.CHIME__c = newChime.Id;
                cpa.Chime_Product_Template__c = mapProductTemplate.get(prodId).Id;
                cpa.Review_Required__c = true;
                CPAToBeCreated.add(cpa);
            }
            
            insert CPAToBeCreated;

            ChimeTriggerClass.getEnterpriseProductsOnChime(newChime.Id,true);
            
            //Response cloning
            List<CHIME_Response__c> listOldChimeResponses = [Select Id,CHIME__c,CHIME_Product_Question__c ,Response__c from CHIME_Response__c where CHIME__c =:chimeId];
            if(listOldChimeResponses.size()>0){
                List<CHIME_Response__c> listNewChimeResponses = listOldChimeResponses.deepClone(false,false,false);
                for(CHIME_Response__c res: listNewChimeResponses){
                    res.CHIME__c = newChime.Id;
                }
                insert listNewChimeResponses;
            }
            
            //CHIME Contacts Cloning
            List<CHIME_Contact__c> listOldChimeContacts = [Select id,CHIME__c,Chime_access__c ,Contact__c from CHIME_Contact__c where CHIME__c =:chimeId];
            if(listOldChimeContacts.size()>0){
                List<CHIME_Contact__c> listNewChimeContacts = listOldChimeContacts.deepClone(false,false,false);
                for(CHIME_Contact__c con: listNewChimeContacts){
                    con.CHIME__c = newChime.Id;
                }
                insert listNewChimeContacts;
            }
            
            chimePSTClass.loeClone(newChime.Id,chimeForm.Id);
            
            return newChime.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
            
        }
    }
    @AuraEnabled
    public static Id clonePOCToPOCForm(Id chimeId,Id oppId,string chimeFormName){
        try{
            Chime__c chimeForm = [Select Id,Account__c,CHIME_Name__c,Implementation_Type__c,POC_Type__c,Business_Goals__c from chime__c where id=: chimeId];
            //Clone Chime Form
            Chime__c newChime = new Chime__c();      
            newChime.Stage__c ='Gating';
            newChime.Account__c=chimeForm.Account__c;
            newChime.CHIME_Name__c =chimeFormName;
            newChime.Opportunity__c = oppId;
            newChime.Implementation_Type__c = chimeForm.Implementation_Type__c;
            newChime.Is_POC_Demo__c = true;
            newChime.POC_Type__c = chimeForm.POC_Type__c;
            newChime.Business_Goals__c= chimeForm.Business_Goals__c;
			insert newChime;   
            System.debug('newChime'+newChime);
                
            //Clone CPAs
            List<Chime_Product_Association__c> OldCPAList = [Select Id,CHIME_Product__c,CHIME__c from Chime_Product_Association__c where CHIME__c=:chimeId];
            
            List<Id> prodList = new List<Id>();
            for(Chime_Product_Association__c cpa : OldCPAList){
                prodList.add(cpa.CHIME_Product__c);
            }

			//List<Chime_Product_Association__c > CPAs = [Select id,]
            List<Chime_Product_Association__c > CPAToBeCreated = new List<Chime_Product_Association__c >();
            Map<Id,Chime_Product_Template__c> mapProductTemplate = new Map<Id,Chime_Product_Template__c>();
            
            List<Chime_Product_Template__c> prodTemplateList = [Select id,Product__c,createddate from Chime_Product_Template__c where Product__c in:prodList order by createddate desc];
            
            //create map of product and template
            for(Chime_Product_Template__c template : prodTemplateList){
                if(!mapProductTemplate.containsKey(template.Product__c)){
                	mapProductTemplate.put(template.Product__c,template);
                }else{
                    if(template.CreatedDate > mapProductTemplate.get(template.Product__c).createddate){
                        mapProductTemplate.put(template.Product__c,template);
                    }
                }
            }
            
            
            for(String product :prodList){
                Id prodId = (Id)product;
                Chime_Product_Association__c cpa = new Chime_Product_Association__c();
                cpa.CHIME_Product__c =(Id)product;
                cpa.CHIME__c = newChime.Id;
                cpa.Chime_Product_Template__c = mapProductTemplate.get(prodId).Id;
                CPAToBeCreated.add(cpa);
            }
            
            insert CPAToBeCreated;

            ChimeTriggerClass.getEnterpriseProductsOnChime(newChime.Id,true);
            
            //Response cloning
            List<CHIME_Response__c> listOldChimeResponses = [Select Id,CHIME__c,CHIME_Product_Question__c ,Response__c from CHIME_Response__c where CHIME__c =:chimeId];
            if(listOldChimeResponses.size()>0){
                List<CHIME_Response__c> listNewChimeResponses = listOldChimeResponses.deepClone(false,false,false);
                for(CHIME_Response__c res: listNewChimeResponses){
                    res.CHIME__c = newChime.Id;
                }
                insert listNewChimeResponses;
            }
            
            //CHIME Contacts Cloning
            List<CHIME_Contact__c> listOldChimeContacts = [Select id,CHIME__c,Chime_access__c ,Contact__c from CHIME_Contact__c where CHIME__c =:chimeId];
            if(listOldChimeContacts.size()>0){
                List<CHIME_Contact__c> listNewChimeContacts = listOldChimeContacts.deepClone(false,false,false);
                for(CHIME_Contact__c con: listNewChimeContacts){
                    con.CHIME__c = newChime.Id;
                }
                insert listNewChimeContacts;
            }
            
            //GSS method to copy features
            chimePSTClass.loeClone(newChime.Id,chimeForm.Id);
            
            return newChime.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
            
        }
    }
}