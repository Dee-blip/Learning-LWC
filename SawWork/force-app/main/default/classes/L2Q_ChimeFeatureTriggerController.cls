public class L2Q_ChimeFeatureTriggerController {
        //Method to update LOE on Chime Product
    public static void updateProductLOE(List<Chime_Features_LoE__c> oldList){
        List<Id> parentProductIdList = new List<Id>();
        Map<Id,Chime_Product_Association__c> parentProductMap = new Map<Id,Chime_Product_Association__c>();
        List<Chime_Product_Association__c> toBeUpdatedCPA = new List<Chime_Product_Association__c>();
        
        for(Chime_Features_LoE__c iteratedChimefeature : oldList){
            if(iteratedChimefeature.Is_Selected__c)
            parentProductIdList.add(iteratedChimefeature.Chime_Product__c);
        }
        if(parentProductIdList.size() > 0){
            parentProductMap = new Map<Id,Chime_Product_Association__c>([Select Id,Total_LoE__c from Chime_Product_Association__c where Id IN: parentProductIdList]);
            for(Chime_Features_LoE__c iteratedChimefeature : oldList){
                if(iteratedChimefeature.Is_Selected__c){
                    parentProductMap.get(iteratedChimefeature.Chime_Product__c).Total_LoE__c = parentProductMap.get(iteratedChimefeature.Chime_Product__c).Total_LoE__c - iteratedChimefeature.LoE__c;

                }
            }
            update parentProductMap.values();
        }

    }
}